-- Run before deploying the corrected Worker.
-- Lets the link checker retry an inconclusive result a few times, then give up,
-- rather than either condemning the link or retrying it for ever.

alter table resource
  add column if not exists check_attempts int not null default 0;

-- Reset the damage from the first run: put everything back in the queue,
-- but keep http_status so the evidence of what happened survives.
update resource
set verification = 'unverified',
    check_attempts = 0
where verification in ('removed', 'stale');
