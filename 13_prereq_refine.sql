-- Prereq for the audience-refinement pass (Worker step ?step=refine).
-- Run before deploying the updated Worker.

alter table org
  add column if not exists older_people_relevant boolean,
  add column if not exists audience_checked boolean not null default false,
  add column if not exists refine_notes text;

-- provision_type from sql/16 stays; this pass may also correct it.
-- Only voluntary, currently-eligible rows are in scope.
