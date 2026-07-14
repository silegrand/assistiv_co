-- Run before deploying the geocode + charity-tag Worker steps.

alter table org add column if not exists district text;
alter table org add column if not exists relevance_checked boolean not null default false;

-- CQC rows were already relevance-decided via the category map, so mark them
-- checked to keep them out of the charity-tagging queue.
update org set relevance_checked = true where primary_source = 'CQC';

create index if not exists org_district_idx on org (district);
