-- ---------------------------------------------------------------------------
-- ReferKent services: stage, check overlap, load only the new ones.
--
-- Source: KCC / ReferKent directory export (Services_in_Kent.xlsx), cleaned to
-- 172 unique services. Provenance tagged 'ReferKent' so we can always show KCC
-- exactly what came from their data vs what Assistiv added.
--
-- Run in three stages, like the charity spine:
--   A. create staging table (this file, top)
--   B. import refkent_services.csv into refkent_stage via Table Editor
--   C. run the overlap report, then the insert (this file, lower)
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- STAGE A. Run first.
-- ===========================================================================
drop table if exists refkent_stage;

create table refkent_stage (
  name text,
  address text,
  postcode text,
  email text,
  phone text,
  website text
);

-- ===========================================================================
-- STAGE B (no SQL): Table Editor -> refkent_stage -> Import data from CSV
--                   -> upload refkent_services.csv
-- ===========================================================================


-- ===========================================================================
-- STAGE C. Run after the CSV is imported.
-- ===========================================================================

-- C1. Sanity: how many staged?  (expect ~172)
select count(*) as staged from refkent_stage;

-- C2. THE YIELD REPORT. How many are genuinely new vs already in org.
--     Matches an existing org by name (case-insensitive) OR by website domain,
--     which catches "Age UK Thanet" appearing under slightly different names.
with staged as (
  select
    s.*,
    lower(trim(s.name)) as name_key,
    -- crude domain extract from website for a second match signal
    lower(regexp_replace(coalesce(s.website,''), '^https?://(www\.)?([^/]+).*$', '\2')) as web_domain
  from refkent_stage s
),
matched as (
  select
    st.*,
    exists (
      select 1 from org o
      where lower(o.name) = st.name_key
    ) as name_exists,
    exists (
      select 1 from org o
      where st.web_domain <> ''
        and lower(regexp_replace(coalesce(o.website,''), '^https?://(www\.)?([^/]+).*$', '\2')) = st.web_domain
    ) as web_exists
  from staged st
)
select
  count(*) filter (where name_exists or web_exists) as already_have,
  count(*) filter (where not (name_exists or web_exists)) as genuinely_new,
  count(*) as total
from matched;

-- C3. LIST the genuinely-new ones, so you can eyeball before loading.
with staged as (
  select s.*, lower(trim(s.name)) as name_key,
    lower(regexp_replace(coalesce(s.website,''), '^https?://(www\.)?([^/]+).*$', '\2')) as web_domain
  from refkent_stage s
)
select st.name, st.postcode, st.website
from staged st
where not exists (select 1 from org o where lower(o.name) = st.name_key)
  and not exists (
    select 1 from org o
    where st.web_domain <> ''
      and lower(regexp_replace(coalesce(o.website,''), '^https?://(www\.)?([^/]+).*$', '\2')) = st.web_domain
  )
order by st.name;


-- ===========================================================================
-- C4. THE INSERT. Run once you are happy with the C3 list.
-- Loads only the new ones, staged unverified/untagged so the existing pipeline
-- (geocode -> refine -> ctag -> summarise -> links) processes them like any
-- other voluntary org. Provenance = 'ReferKent'.
-- ===========================================================================
begin;

insert into org (
  name, sector, description, address, postcode, email, phone, website,
  primary_source, source_url, verification, tagged, relevance_checked, summarised
)
select
  st.name,
  'voluntary',
  null,                              -- no clean description in the export; refine reads name+category
  nullif(st.address, ''),
  nullif(st.postcode, ''),
  nullif(st.email, ''),
  nullif(st.phone, ''),
  nullif(st.website, ''),
  'ReferKent',
  'https://kentcountycouncil.refernet.co.uk/',
  'unverified',
  false,
  false,
  false
from refkent_stage st
where st.name is not null
  and not exists (select 1 from org o where lower(o.name) = lower(trim(st.name)))
  and not exists (
    select 1 from org o
    where coalesce(st.website,'') <> ''
      and lower(regexp_replace(coalesce(o.website,''),  '^https?://(www\.)?([^/]+).*$', '\2'))
        = lower(regexp_replace(coalesce(st.website,''), '^https?://(www\.)?([^/]+).*$', '\2'))
  );

commit;

drop table refkent_stage;

-- What landed.
select primary_source, count(*) as orgs
from org
where primary_source = 'ReferKent'
group by primary_source;
