-- The column the tagging step needs. This was previously given only as a loose
-- snippet in chat, and appears not to have been run, which is why /ingest was
-- reporting untagged: 0 while no org had ever been tagged.
--
-- Run this in the Supabase SQL editor before redeploying the Worker.

alter table org
  add column if not exists tag_attempts int not null default 0;

-- Confirm it worked. Should return 4100 (or thereabouts), not 0.
select count(*) as orgs_awaiting_tagging
from org
where tagged = false and tag_attempts < 3;
