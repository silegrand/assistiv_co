-- ---------------------------------------------------------------------------
-- ReferKent: load the 98 new services, then verify placement.
-- Table is "Referkent" (capital R, quoted) per the import.
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- STEP 1. Load only the genuinely-new ones. Provenance = 'ReferKent'.
-- ===========================================================================
begin;

insert into org (
  name, sector, description, address, postcode, email, phone, website,
  primary_source, source_url, verification, tagged, relevance_checked, summarised
)
select
  st.name, 'voluntary', null,
  nullif(st.address, ''), nullif(st.postcode, ''),
  nullif(st.email, ''), nullif(st.phone, ''), nullif(st.website, ''),
  'ReferKent', 'https://kentcountycouncil.refernet.co.uk/',
  'unverified', false, false, false
from "Referkent" st
where st.name is not null
  and not exists (select 1 from org o where lower(o.name) = lower(trim(st.name)))
  and not exists (
    select 1 from org o
    where coalesce(st.website,'') <> ''
      and lower(regexp_replace(coalesce(o.website,''),  '^https?://(www\.)?([^/]+).*$', '\2'))
        = lower(regexp_replace(coalesce(st.website,''), '^https?://(www\.)?([^/]+).*$', '\2'))
  );

commit;

-- confirm the load (~98)
select count(*) as referkent_loaded
from org where primary_source = 'ReferKent';


-- ===========================================================================
-- STEP 2. Now run the Worker pipeline over them, in this order:
--   /ingest?step=geocode&n=45     -> lat/lng + district
--   /ingest?step=refine&n=8       -> older_people_relevant, service vs venue
--   /ingest?step=ctag&n=8         -> ASCOT domains
--   /ingest?step=summarise&n=8    -> plain sentence
--   /ingest?step=links&n=15       -> verify websites
-- (Only ReferKent rows are unprocessed, so these passes only touch them.)
-- ===========================================================================


-- ===========================================================================
-- STEP 3. After geocode: WHERE did they land? Non-Kent districts are phantoms
-- (out-of-area HQs serving Kent). Kent+Medway districts are the real ones.
-- ===========================================================================
select
  coalesce(district, '(ungeocoded)') as district,
  count(*) as n,
  case when district = any(kent_districts()) then 'KENT' else 'OUT OF AREA' end as in_scope
from org
where primary_source = 'ReferKent'
group by district
order by in_scope, n desc;

-- Exclude the out-of-area phantoms from the takeaway (kept in db, flagged).
update org
set takeaway_eligible = false,
    eligibility_notes = 'ReferKent: registered outside Kent/Medway, out of scope. '
                        || coalesce(eligibility_notes,'')
where primary_source = 'ReferKent'
  and district is not null
  and not (district = any(kent_districts()));


-- ===========================================================================
-- STEP 4. After refine + ctag + summarise: what actually survived as usable
-- older-people provision, and how it splits.
-- ===========================================================================
select
  count(*) filter (where takeaway_eligible) as in_takeaway,
  count(*) filter (where older_people_relevant) as older_relevant,
  count(*) filter (where provision_type='service') as services,
  count(*) filter (where provision_type='venue') as venues,
  count(*) as total
from org
where primary_source = 'ReferKent';

-- The keepers, to eyeball.
select name, district, provision_type, plain_summary
from org
where primary_source = 'ReferKent' and takeaway_eligible
order by district, name;
