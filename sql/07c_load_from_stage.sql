-- STEP C. Run this after the CSV import has filled charity_stage.
-- Moves the charities into org, skipping anything already there.

-- Sanity check before we commit to anything. Should be 5019.
select count(*) as staged from charity_stage;

begin;

insert into org (
  name, sector, description, address, postcode, phone, email, website,
  charity_number, income, primary_source, source_url, verification, tagged
)
select
  s.name,
  'voluntary',
  nullif(s.activities, ''),
  nullif(s.address, ''),
  nullif(s.postcode, ''),
  nullif(s.phone, ''),
  nullif(s.email, ''),
  nullif(s.website, ''),
  s.charity_number,
  s.income,
  'Charity Commission',
  'https://register-of-charities.charitycommission.gov.uk/charity-search/-/charity-details/'
    || s.charity_number,
  'unverified',
  false
from charity_stage s
where s.name is not null
  -- not already loaded from a previous run
  and not exists (
    select 1 from org o where o.charity_number = s.charity_number
  )
  -- not the same organisation we already hold from CQC
  and not exists (
    select 1 from org o
    where lower(o.name) = lower(s.name)
      and coalesce(o.postcode, '') = coalesce(nullif(s.postcode, ''), '')
  );

commit;

drop table charity_stage;

-- What landed.
select
  primary_source,
  count(*) as orgs,
  count(*) filter (where postcode is not null) as with_postcode,
  count(*) filter (where website is not null)  as with_website
from org
group by primary_source
order by orgs desc;
