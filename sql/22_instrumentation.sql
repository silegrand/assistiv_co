-- Instrumentation for the AI tagging passes.
-- Run once in the Supabase SQL editor BEFORE deploying the updated Worker.
--
-- ctag_reason : one short clause from tagCharity explaining WHY a charity was
--               judged eligible or not. Without this, an exclusion decision
--               leaves no trace and has to be re-read by hand.
-- tag_error   : the actual exception message when an AI tagging call fails,
--               prefixed with the step name (tag/ctag/refine/summarise). Without
--               this, a transient Anthropic failure can retire hundreds of real
--               rows and the only trace is a counter reading "retired: N".

alter table org add column if not exists tag_error   text;
alter table org add column if not exists ctag_reason text;

-- Useful afterwards:
--   why things were excluded
--     select ctag_reason, count(*) from org
--     where sector='voluntary' and takeaway_eligible is false
--     group by 1 order by count desc;
--
--   did a batch die, and why
--     select tag_error, count(*) from org
--     where tag_error is not null group by 1 order by count desc;
