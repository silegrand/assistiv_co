-- ---------------------------------------------------------------------------
-- PROVISION TYPE
--
-- The scorecard's honesty depends on one distinction: is an entry a SERVICE a
-- person can attend, or a VENUE that merely might host one?
--
--   service  A thing with its own activity: befriending, lunch club, day
--            centre, meals, a support group, an advice service. Attending it
--            helps directly. Real provision.
--   venue    A room for hire: village hall, community centre, sports pavilion.
--            May host exactly what the person needs, or may host nothing
--            relevant. Cannot be counted as confirmed provision.
--   unknown  Text too thin to tell. Goes to the AI pass or an enrichment sweep.
--
-- Why this matters for Assistiv's build decisions: a district full of village
-- halls scores as "well provided" on venue count but may have no actual older-
-- people activity. The gap-map must be built on SERVICES, with venues shown
-- separately as leads for the next enrichment sweep.
--
-- This does the confident cases by rule. Genuinely ambiguous rows are left
-- 'unknown' for a small AI pass (Worker step ?step=ptype), not a full re-tag.
-- ---------------------------------------------------------------------------

begin;

alter table org add column if not exists provision_type text
  check (provision_type in ('service','venue','unknown'));

-- --- VENUES: high-confidence room-for-hire signals -------------------------
update org
set provision_type = 'venue'
where sector = 'voluntary' and takeaway_eligible
  and (
    name ilike '%village hall%' or
    name ilike '%memorial hall%' or
    name ilike '%parish hall%' or
    name ilike '%church hall%' or
    name ilike '%community centre%' or
    name ilike '%community hall%' or
    name ilike '%sports pavilion%' or
    name ilike '%recreation ground%' or
    name ilike '%playing field%' or
    (name ilike '%community association%'
       and (description ilike '%hire%' or description ilike '%village hall%'
            or description ilike '%community centre%'))
  )
  -- but NOT if the text describes a specific programmed service for this cohort
  and not (
    description ilike '%lunch club%' or description ilike '%befriend%' or
    description ilike '%day centre%' or description ilike '%over 60%' or
    description ilike '%older people%' or description ilike '%elderly%'
  );

-- --- SERVICES: high-confidence programmed-activity signals ------------------
update org
set provision_type = 'service'
where sector = 'voluntary' and takeaway_eligible
  and provision_type is null
  and (
    description ilike '%befriend%' or description ilike '%lunch club%' or
    description ilike '%day centre%' or description ilike '%day care%' or
    description ilike '%meals%' or description ilike '%good neighbour%' or
    description ilike '%support group%' or description ilike '%drop-in%' or
    description ilike '%drop in%' or description ilike '%advice%' or
    description ilike '%counsel%' or description ilike '%carers%' or
    description ilike '%dementia%' or description ilike '%bereavement%' or
    description ilike '%visiting%' or description ilike '%helpline%' or
    name ilike '%befriend%' or name ilike '%day centre%' or
    name ilike '%age uk%' or name ilike '%age concern%' or
    name ilike '%good neighbour%'
  );

-- --- everything else eligible but unclassified = unknown -------------------
update org
set provision_type = 'unknown'
where sector = 'voluntary' and takeaway_eligible and provision_type is null;

commit;

-- ---------------------------------------------------------------------------
-- What the split looks like.
-- ---------------------------------------------------------------------------
select provision_type, count(*) as n
from org
where sector = 'voluntary' and takeaway_eligible
group by provision_type
order by n desc;

-- Sample of each, to sanity-check the rules before trusting them.
select provision_type, name, left(description, 80) as activities
from org
where sector = 'voluntary' and takeaway_eligible
  and provision_type in ('service','venue','unknown')
order by provision_type, random()
limit 30;
