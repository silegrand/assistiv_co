-- Kent + Medway directory: non-geocoded advice layer.
-- Run once in the Supabase SQL editor, after the existing consolidated schema.
-- Safe to re-run.

-- A resource is a page, helpline, scheme or guide. It has no location.
-- Distinct from `org`, which is a place a person can physically go to.
create table if not exists resource (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text not null unique,
  category text,                       -- KCC's own taxonomy, kept deliberately
  scope text not null check (scope in ('national','kent')),
  provider_type sector,                -- reuses the existing enum
  description text,
  primary_source text not null,
  last_verified timestamptz,
  http_status int,                     -- populated by the link checker
  verification verification_status not null default 'unverified',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists resource_domain (
  resource_id uuid references resource(id) on delete cascade,
  domain text not null,
  confidence numeric,
  method tag_method not null default 'manual',
  model text,
  primary key (resource_id, domain)
);

create index if not exists resource_scope_idx  on resource (scope);
create index if not exists resource_domain_idx on resource_domain (domain);

alter table resource enable row level security;
alter table resource_domain enable row level security;

-- Only surface a resource once the link checker has confirmed it resolves.
-- An unchecked or dead link is worse than no link at all for this cohort.
drop policy if exists "public read resource" on resource;
create policy "public read resource" on resource
  for select using (verification = 'verified');

drop policy if exists "public read resource tags" on resource_domain;
create policy "public read resource tags" on resource_domain
  for select using (true);


-- ---------------------------------------------------------------------------
-- The takeaway query. Given the domains a person scored poorly on, return the
-- advice layer ordered by relevance. Kent-specific beats national on a tie.
-- Excludes commercial providers unless explicitly asked for, so the default
-- takeaway does not read as an advertising hoarding.
-- ---------------------------------------------------------------------------
create or replace function takeaway_resources(
  p_domains text[],
  p_include_commercial boolean default false,
  p_limit int default 30
)
returns table (
  title text,
  url text,
  category text,
  scope text,
  provider_type sector,
  matched_domains text[],
  relevance numeric
)
language sql stable as $$
  select
    r.title,
    r.url,
    r.category,
    r.scope,
    r.provider_type,
    array_agg(rd.domain order by rd.confidence desc) as matched_domains,
    round(sum(rd.confidence)::numeric, 2)
      + case when r.scope = 'kent' then 0.5 else 0 end as relevance
  from resource r
  join resource_domain rd on rd.resource_id = r.id
  where rd.domain = any(p_domains)
    and r.verification = 'verified'
    and (p_include_commercial or r.provider_type is distinct from 'commercial')
  group by r.id, r.title, r.url, r.category, r.scope, r.provider_type
  order by relevance desc, r.title
  limit p_limit;
$$;
