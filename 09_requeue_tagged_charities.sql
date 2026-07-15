-- Reset the ~200 charities already tagged, so they re-run through the corrected
-- prompt (faith-based services no longer wrongly excluded; substance misuse now
-- excluded). Their existing domain rows are cleared first so nothing stale
-- lingers. Costs a couple of dollars to re-tag; worth it to confirm the fix.

begin;

-- clear domains for the already-tagged charities
delete from org_domain
where org_id in (
  select id from org where sector = 'voluntary' and relevance_checked = true
);

-- reset their flags so ctag picks them up again
update org
set relevance_checked = false,
    tagged = false,
    takeaway_eligible = null,
    self_referable = null,
    tag_attempts = 0
where sector = 'voluntary' and relevance_checked = true;

commit;

select count(*) as charities_requeued
from org where sector = 'voluntary' and relevance_checked = false;
