-- ---------------------------------------------------------------------------
-- ELIGIBILITY REVIEW
--
-- The AI relevance pass marked ~832 charities takeaway_eligible. It is good but
-- not perfect. This set surfaces the likely errors first, so the review is an
-- hour of looking at suspects, not a cold read of 832 rows.
--
-- Workflow: run each query, eyeball, and for any genuine false positive collect
-- its id. Then run the correction block at the foot with those ids.
--
-- A "false positive" here means: marked eligible, but NOT something a person
-- screening at home for loneliness/decline could usefully attend or contact.
-- Care providers, preservation trusts, sports clubs for the able-bodied young,
-- animal charities, purely administrative bodies, etc.
-- ---------------------------------------------------------------------------

-- 1. HIGH-RISK KEYWORDS IN THE NAME
--    Names that often signal something that slipped through. Read the activities
--    column and judge each.
select id, name, left(description, 100) as activities,
       (select array_agg(domain) from org_domain d where d.org_id = o.id) as domains
from org o
where sector = 'voluntary' and takeaway_eligible
  and (
    name ilike '%care%' or            -- care providers (allocated, not self-referable)
    name ilike '%nursing%' or
    name ilike '%preservation%' or    -- buildings/heritage, not people
    name ilike '%heritage%' or
    name ilike '%trust%' and description ilike '%grant%' or  -- grant-givers
    name ilike '%football%' or        -- youth sport
    name ilike '%rugby%' or
    name ilike '%scout%' or
    name ilike '%guide%' or
    name ilike '%school%' or
    name ilike '%academy%' or
    name ilike '%pre-school%' or
    name ilike '%playgroup%' or
    name ilike '%animal%' or
    name ilike '%rescue%'
  )
order by name;

-- 2. ELIGIBLE BUT NO USABLE CONTACT
--    If it has no phone, no website, and only a vague address, a person cannot
--    act on it even if it is relevant. Candidates for exclusion or enrichment.
select id, name, postcode,
       (select array_agg(domain) from org_domain d where d.org_id = o.id) as domains
from org o
where sector = 'voluntary' and takeaway_eligible
  and phone is null and website is null
order by name
limit 100;

-- 3. SINGLE-DOMAIN, LOW-CONFIDENCE
--    Charities tagged with just one domain at low confidence are the weakest
--    inclusions. Worth a skim.
select o.id, o.name, d.domain, d.confidence, left(o.description,90) as activities
from org o
join org_domain d on d.org_id = o.id
where o.sector = 'voluntary' and o.takeaway_eligible
  and d.confidence < 0.4
  and (select count(*) from org_domain d2 where d2.org_id = o.id) = 1
order by d.confidence
limit 100;

-- 4. THE CONFIDENCE-YOU-CAN-SEE CHECK
--    Distribution of how many domains each eligible charity got. A charity with
--    5+ domains is either a genuine multi-service hub or an over-eager tag.
select ndomains, count(*) as charities
from (
  select o.id, count(d.domain) as ndomains
  from org o join org_domain d on d.org_id = o.id
  where o.sector='voluntary' and o.takeaway_eligible
  group by o.id
) x
group by ndomains order by ndomains;

-- 5. SANITY: the clearly-good ones, so you can calibrate what "right" looks like
--    before judging the suspects.
select name, left(description,90) as activities,
       (select array_agg(domain) from org_domain d where d.org_id = o.id) as domains
from org o
where sector='voluntary' and takeaway_eligible
  and (name ilike '%community association%' or name ilike '%good neighbour%'
       or name ilike '%befriend%' or name ilike '%lunch%' or name ilike '%over 60%'
       or name ilike '%day centre%' or name ilike '%village hall%')
order by name
limit 40;


-- ---------------------------------------------------------------------------
-- CORRECTION BLOCK
-- Once you have the ids of genuine false positives, list them here and run.
-- This excludes them from the takeaway but keeps them in the database.
-- ---------------------------------------------------------------------------
/*
update org
set takeaway_eligible = false,
    eligibility_notes = 'Manual review: not a self-referable service for the
                         screening cohort. ' || coalesce(eligibility_notes,''),
    updated_at = now()
where id in (
  -- paste ids here, comma-separated
  '00000000-0000-0000-0000-000000000000'
);

-- confirm the new eligible count
select count(*) as eligible_after_review
from org where sector='voluntary' and takeaway_eligible;
*/
