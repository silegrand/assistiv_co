-- Column for the one-line, plain-English summary shown in the takeaway.
-- Generated once from the service's own activity text by the Worker
-- (?step=summarise), never invented. Run before deploying that step.

alter table org
  add column if not exists plain_summary text,
  add column if not exists summarised boolean not null default false;
