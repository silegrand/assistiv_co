-- 00 base schema. Run first. Creates the core tables everything else builds on.
-- Reconstructed from the original consolidated schema.

create extension if not exists postgis;

do $$ begin
  create type sector as enum ('statutory','health','voluntary','community','commercial','other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type verification_status as enum ('verified','stale','unverified','removed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type tag_method as enum ('source','ai','manual');
exception when duplicate_object then null; end $$;

-- canonical, de-duplicated organisation (a place a person can go to)
create table if not exists org (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sector sector not null,
  category text,
  description text,
  address text,
  postcode text,
  lat double precision,
  lng double precision,
  location geography(Point,4326) generated always as (
    case when lat is not null and lng is not null
      then st_setsrid(st_makepoint(lng, lat), 4326)::geography
    end
  ) stored,
  phone text,
  email text,
  website text,
  districts text[] default '{}',
  coverage text,
  eligibility_notes text,
  tagged boolean not null default false,
  primary_source text not null,
  source_url text,
  last_verified timestamptz,
  verification verification_status not null default 'unverified',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- provenance: every source that feeds an org
create table if not exists org_source (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references org(id) on delete cascade,
  source text not null,
  source_id text,
  source_url text,
  fetched_at timestamptz not null default now(),
  raw jsonb,
  unique (source, source_id)
);

-- ASCOT domain tags
create table if not exists org_domain (
  org_id uuid references org(id) on delete cascade,
  domain text not null,
  confidence numeric,
  method tag_method not null default 'ai',
  model text,
  primary key (org_id, domain)
);

-- ingestion queue/cursor for the CQC pipeline
create table if not exists ingest_state (
  id text primary key,
  pending jsonb not null default '[]',
  seen int not null default 0,
  upserted int not null default 0,
  last_seed timestamptz,
  updated_at timestamptz default now()
);

create index if not exists org_location_gix   on org using gist (location);
create index if not exists org_districts_gin   on org using gin (districts);
create index if not exists org_domain_domain_idx on org_domain (domain);

alter table org enable row level security;
alter table org_domain enable row level security;

drop policy if exists "public read org" on org;
create policy "public read org" on org for select using (verification = 'verified');

drop policy if exists "public read tags" on org_domain;
create policy "public read tags" on org_domain for select using (true);
