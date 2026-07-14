-- ---------------------------------------------------------------------------
-- Product decision: substance misuse services are excluded from the takeaway.
--
-- They remain in the database, queryable and correctly described. They are not
-- surfaced to someone who has just completed a preventative wellbeing screen.
-- Presenting a drug and alcohol service to an isolated 82-year-old who scored
-- badly on social participation is at best irrelevant and at worst reads as an
-- accusation.
--
-- Note the honest consequence: this removes the largest single block from the
-- CQC layer's social-participation count, taking it from 79 to roughly 26.
-- That is a truer number and it strengthens the gap argument rather than
-- weakening it.
-- ---------------------------------------------------------------------------

begin;

-- 1. CQC layer: fix the category map so this cannot come back on a re-run.
update category_map
set takeaway_eligible = false,
    note = 'Excluded from takeaway by product decision: not appropriate to surface
             to an older adult completing a preventative wellbeing screen.'
where category in (
  'Community services - Substance abuse',
  'Rehabilitation (substance abuse)'
);

-- 2. Apply to the existing CQC rows.
update org o
set takeaway_eligible = false,
    updated_at = now()
from category_map cm
where cm.category = o.category
  and cm.takeaway_eligible = false
  and o.takeaway_eligible is distinct from false;

-- 3. Any charities already tagged eligible whose activities are substance
--    misuse. Conservative text match; review the output before trusting it.
update org
set takeaway_eligible = false,
    updated_at = now()
where sector = 'voluntary'
  and takeaway_eligible
  and (
    description ilike '%substance misuse%' or
    description ilike '%substance abuse%' or
    description ilike '%drug and alcohol%' or
    description ilike '%drugs and alcohol%' or
    description ilike '%alcohol misuse%' or
    description ilike '%addiction%'
  );

commit;

-- ---------------------------------------------------------------------------
-- Check the effect.
-- ---------------------------------------------------------------------------

-- The honest social/occupation numbers for the CQC layer, post-decision.
select d.domain, count(*) as n
from org_domain d
join org o on o.id = d.org_id
where o.takeaway_eligible and o.primary_source = 'CQC'
group by d.domain
order by n desc;

-- Which charities this caught, so you can eyeball for false positives.
select name, left(description, 80) as activities
from org
where sector = 'voluntary'
  and takeaway_eligible = false
  and (description ilike '%alcohol%' or description ilike '%addiction%' or description ilike '%substance%')
limit 20;
