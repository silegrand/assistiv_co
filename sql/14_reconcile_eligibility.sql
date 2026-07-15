-- ---------------------------------------------------------------------------
-- Reconcile eligibility after the refine pass.
--
-- Two corrections:
--
-- 1. FALSE EXCLUSIONS. The refine step only ever set takeaway_eligible = false;
--    it never set it back true. So ~24 charities judged older_people_relevant
--    = true were left ineligible because of a prior flag state. They are real
--    older-people services and must be in the takeaway. This under-counts
--    provision, which for a build-decision gap map is the dangerous direction.
--
-- 2. VENUES AS LEADS. Village halls et al are correctly not "confirmed
--    provision" and correctly not in the person-facing takeaway. But they are
--    not nothing: they are places that may host relevant activity, and they are
--    the lead list for the next enrichment sweep. Give them a distinct status
--    so the gap map can show them as a separate layer rather than losing them.
-- ---------------------------------------------------------------------------

begin;

-- 1. Any refined charity judged relevant is eligible, full stop.
update org
set takeaway_eligible = true,
    updated_at = now()
where sector = 'voluntary'
  and audience_checked
  and older_people_relevant = true
  and takeaway_eligible is distinct from true;

-- 2. A lead flag for venues: not confirmed provision, not in the takeaway,
--    but retained as enrichment targets. Kept separate from eligibility.
alter table org add column if not exists is_lead boolean not null default false;

update org
set is_lead = true
where sector = 'voluntary'
  and audience_checked
  and provision_type = 'venue'
  and takeaway_eligible = false;

commit;

-- ---------------------------------------------------------------------------
-- Recount, so we know the true shape.
-- ---------------------------------------------------------------------------
select
  case
    when takeaway_eligible then 'confirmed_service'
    when is_lead           then 'venue_lead'
    else                        'excluded'
  end as bucket,
  count(*) as n
from org
where sector = 'voluntary' and audience_checked
group by 1
order by n desc;
