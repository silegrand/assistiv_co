-- ---------------------------------------------------------------------------
-- Category-based ASCOT tagging for the CQC layer.
--
-- Replaces the per-org Anthropic tagging pass. The tagger only ever saw
-- name, category and description, and `description` is null on every CQC row.
-- So 4,100 API calls would have been asking the same 30 questions repeatedly:
-- every one of the 985 homecare agencies gets an identical prompt, as does
-- every one of the 768 dentists. Thirty hand-made decisions give the same
-- answer, more accurately, auditably, and for nothing.
--
-- Two further judgements are encoded here that the AI tagger could not make,
-- because they are product decisions rather than semantic ones:
--
--   takeaway_eligible  Should this appear on the map handed to someone who
--                      has just completed the screening and is living at home?
--                      A residential home is not an action a person can take.
--                      Showing one to a frail person who has just scored badly
--                      is at best useless and at worst frightening.
--
--   self_referable     Can a member of the public contact this directly, or
--                      does it need a professional referral? Signposting
--                      someone to a service they cannot access on their own is
--                      a failure dressed up as help.
--
-- Run after 05_add_tag_attempts.sql. Idempotent.
-- ---------------------------------------------------------------------------

begin;

-- --- product flags on org ---------------------------------------------------
alter table org
  add column if not exists takeaway_eligible boolean,
  add column if not exists self_referable   boolean;

-- --- the mapping tables -----------------------------------------------------
create table if not exists category_map (
  category text primary key,
  correct_sector sector not null,      -- what the sector SHOULD be; not applied here
  takeaway_eligible boolean not null,
  self_referable boolean not null,
  note text
);

create table if not exists category_domain (
  category text references category_map(category) on delete cascade,
  domain text not null,
  confidence numeric not null,
  primary key (category, domain)
);

-- --- the thirty decisions ---------------------------------------------------
insert into category_map (category, correct_sector, takeaway_eligible, self_referable, note) values
  ('Homecare agencies',                        'commercial', true,  true,  'Mostly privately purchased. Actionable, but at a cost.'),
  ('Residential homes',                        'commercial', false, true,  'Not an action for someone living at home. Excluded from the takeaway.'),
  ('Nursing homes',                            'commercial', false, true,  'As above.'),
  ('Dentist',                                  'commercial', true,  true,  'Mostly private or mixed NHS. Self-referable.'),
  ('Doctors/Gps',                              'health',     true,  true,  'Registration required but self-referable.'),
  ('Clinic',                                   'commercial', true,  true,  'Largely private providers.'),
  ('Mobile doctors',                           'commercial', true,  true,  null),
  ('Diagnosis/screening',                      'health',     false, false, 'Referral only. Not actionable.'),
  ('Supported living',                         'other',      false, false, 'Allocated via social care. Not self-referable.'),
  ('Supported housing',                        'voluntary',  false, false, 'Allocated. Not self-referable.'),
  ('Shared lives',                             'voluntary',  false, false, 'Allocated via the local authority.'),
  ('Community services - Substance abuse',     'health',     true,  true,  'Many accept self-referral.'),
  ('Rehabilitation (substance abuse)',         'health',     true,  true,  null),
  ('Community services - Healthcare',          'health',     true,  false, null),
  ('Community services - Nursing',             'health',     true,  false, 'District nursing. Referral only.'),
  ('Community services - Mental Health',       'health',     true,  true,  'Some routes accept self-referral.'),
  ('Community services - Learning disabilities','health',    true,  false, null),
  ('Community health service',                 'health',     true,  false, null),
  ('Rehabilitation (illness/injury)',          'health',     true,  false, null),
  ('Long-term conditions',                     'health',     true,  false, null),
  ('Hospice',                                  'voluntary',  true,  true,  'Hospices accept direct contact and support carers too.'),
  ('Urgent care centres',                      'health',     true,  true,  null),
  ('Hospital',                                 'health',     false, false, 'Not a preventative action.'),
  ('Hospitals - Mental health/capacity',       'health',     false, false, null),
  ('Ambulances',                               'health',     false, false, 'Not a signpost.'),
  ('Blood and transplant service',             'health',     false, false, 'Irrelevant to this cohort.'),
  ('Prison healthcare',                        'health',     false, false, 'Irrelevant to this cohort.'),
  ('Specialist college service',               'other',      false, false, 'Young people. Wrong audience.'),
  ('NHS Healthcare Organisation',              'health',     false, false, 'Administrative body, not a service.'),
  ('Phone/online advice',                      'health',     true,  true,  null)
on conflict (category) do update set
  correct_sector    = excluded.correct_sector,
  takeaway_eligible = excluded.takeaway_eligible,
  self_referable    = excluded.self_referable,
  note              = excluded.note;

insert into category_domain (category, domain, confidence) values
  ('Homecare agencies','personal_care',0.9), ('Homecare agencies','food',0.6),
  ('Homecare agencies','safety',0.6), ('Homecare agencies','control',0.5),
  ('Homecare agencies','accommodation',0.4),

  ('Residential homes','accommodation',0.8), ('Residential homes','personal_care',0.8),
  ('Residential homes','food',0.7), ('Residential homes','safety',0.7),
  ('Residential homes','social',0.5),

  ('Nursing homes','personal_care',0.9), ('Nursing homes','accommodation',0.8),
  ('Nursing homes','safety',0.8), ('Nursing homes','food',0.7),

  ('Dentist','personal_care',0.6), ('Dentist','food',0.5), ('Dentist','dignity',0.5),

  ('Doctors/Gps','safety',0.7), ('Doctors/Gps','control',0.5),

  ('Clinic','safety',0.4), ('Clinic','personal_care',0.3),
  ('Mobile doctors','safety',0.6), ('Mobile doctors','control',0.5),
  ('Diagnosis/screening','safety',0.5),

  ('Supported living','accommodation',0.8), ('Supported living','control',0.7),
  ('Supported living','personal_care',0.7), ('Supported living','social',0.5),

  ('Supported housing','accommodation',0.9), ('Supported housing','safety',0.6),
  ('Supported housing','control',0.5),

  ('Shared lives','accommodation',0.8), ('Shared lives','social',0.7),
  ('Shared lives','dignity',0.6), ('Shared lives','personal_care',0.6),

  ('Community services - Substance abuse','safety',0.7),
  ('Community services - Substance abuse','control',0.7),
  ('Community services - Substance abuse','social',0.4),

  ('Rehabilitation (substance abuse)','safety',0.7),
  ('Rehabilitation (substance abuse)','control',0.7),

  ('Community services - Healthcare','safety',0.6),
  ('Community services - Healthcare','personal_care',0.5),

  ('Community services - Nursing','personal_care',0.8),
  ('Community services - Nursing','safety',0.7),

  ('Community services - Mental Health','control',0.6),
  ('Community services - Mental Health','social',0.6),
  ('Community services - Mental Health','safety',0.5),
  ('Community services - Mental Health','dignity',0.4),

  ('Community services - Learning disabilities','social',0.6),
  ('Community services - Learning disabilities','occupation',0.6),
  ('Community services - Learning disabilities','control',0.6),

  ('Community health service','safety',0.5),

  ('Rehabilitation (illness/injury)','occupation',0.6),
  ('Rehabilitation (illness/injury)','safety',0.6),
  ('Rehabilitation (illness/injury)','control',0.5),
  ('Rehabilitation (illness/injury)','personal_care',0.5),

  ('Long-term conditions','control',0.6), ('Long-term conditions','safety',0.5),
  ('Long-term conditions','occupation',0.4),

  ('Hospice','dignity',0.9), ('Hospice','control',0.8),
  ('Hospice','personal_care',0.7), ('Hospice','social',0.6),

  ('Urgent care centres','safety',0.8),
  ('Hospital','safety',0.6),
  ('Hospitals - Mental health/capacity','safety',0.5),
  ('Hospitals - Mental health/capacity','control',0.4),
  ('Ambulances','safety',0.5),
  ('Specialist college service','occupation',0.6),
  ('NHS Healthcare Organisation','safety',0.4),

  ('Phone/online advice','control',0.6), ('Phone/online advice','safety',0.5),
  ('Phone/online advice','social',0.4)
  -- Blood and transplant service, and Prison healthcare, deliberately have no
  -- domains. They are real CQC services and irrelevant to this cohort.
on conflict (category, domain) do update set confidence = excluded.confidence;

-- --- apply to org -----------------------------------------------------------
insert into org_domain (org_id, domain, confidence, method, model)
select o.id, cd.domain, cd.confidence, 'manual', null
from org o
join category_domain cd on cd.category = o.category
on conflict (org_id, domain) do update set
  confidence = excluded.confidence,
  method     = excluded.method;

update org o
set takeaway_eligible = cm.takeaway_eligible,
    self_referable    = cm.self_referable,
    tagged            = true,
    updated_at        = now()
from category_map cm
where cm.category = o.category;

commit;

-- ---------------------------------------------------------------------------
-- Check the work.
-- ---------------------------------------------------------------------------

-- 1. Anything whose category we did not anticipate. Should be empty or tiny.
--    If not, paste the output and I will extend the map.
select o.category, count(*) as n
from org o
left join category_map cm on cm.category = o.category
where cm.category is null
group by o.category
order by n desc;

-- 2. Coverage.
select
  (select count(*) from org)                      as orgs,
  (select count(*) from org where tagged)         as tagged,
  (select count(distinct org_id) from org_domain) as with_domains,
  (select count(*) from org_domain)               as domain_rows,
  (select count(*) from org where takeaway_eligible) as in_takeaway;

-- 3. THE NUMBER. Domain coverage across the whole CQC layer, counting only
--    orgs a person could actually act on.
select d.domain, count(*) as n
from org_domain d
join org o on o.id = d.org_id
where o.takeaway_eligible
group by d.domain
order by n desc;
