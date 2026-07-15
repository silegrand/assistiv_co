-- ---------------------------------------------------------------------------
-- The takeaway.
--
-- A person completes the ASCOT screen. They give a postcode and the domains
-- they scored poorly on. This returns one ranked answer, drawn from all three
-- layers, honouring every guardrail we have built:
--
--   takeaway_eligible = true    no care homes, no hospitals, no ambulance
--                               stations, no substance misuse services
--   self_referable = true       nothing that needs a professional referral
--   verification = 'verified'   nothing dead, nothing unchecked
--   distance                    nearer is better, hard radius cut-off
--   scope                       Kent-specific advice outranks national advice
--
-- Two functions:
--   takeaway(...)         the full result set, places and advice interleaved
--   takeaway_summary(...) the honesty check: what we found, and what we did not
--
-- Run after 12_exclude_substance_misuse.sql and the charity tagging pass.
-- ---------------------------------------------------------------------------

create or replace function takeaway(
  p_lat double precision,
  p_lng double precision,
  p_domains text[],
  p_radius_m int default 8000,
  p_limit_places int default 12,
  p_limit_advice int default 10,
  p_include_commercial boolean default false
)
returns table (
  layer text,                 -- 'place' | 'advice'
  name text,
  detail text,                -- category for a place, scope for advice
  address text,
  postcode text,
  phone text,
  website text,
  lat double precision,
  lng double precision,
  distance_m int,
  matched_domains text[],
  relevance numeric
)
language sql stable as $$
  with here as (
    select st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as g
  ),

  -- Layer 1 + 2: places you can go. CQC services and voluntary organisations
  -- are ranked together, because from the person's point of view they are the
  -- same thing: somewhere near me I can ring or walk into.
  places as (
    select
      'place'::text as layer,
      o.name,
      coalesce(o.category, initcap(o.sector::text)) as detail,
      o.address,
      o.postcode,
      o.phone,
      o.website,
      o.lat,
      o.lng,
      round(st_distance(o.location, h.g))::int as distance_m,
      array_agg(d.domain order by d.confidence desc) as matched_domains,
      round(
        sum(d.confidence)::numeric
        - (st_distance(o.location, h.g) / p_radius_m)::numeric
      , 3) as relevance
    from org o
    cross join here h
    join org_domain d on d.org_id = o.id
    where o.location is not null
      and o.lat <> -999                       -- geocoding sentinel
      and st_dwithin(o.location, h.g, p_radius_m)
      and d.domain = any(p_domains)
      and o.takeaway_eligible
      and o.self_referable
      and (
        -- Voluntary charities: being on the Charity Commission register and
        -- geocoded is sufficient to surface. A registered charity with a phone
        -- number but no website is not "unverified" in any real sense, and
        -- gating on a live website would hide exactly the smallest, most local,
        -- volunteer-run groups the person most needs. The link check enriches
        -- these rows; it does not gate them.
        -- CQC and commercial rows still require verification, where it means
        -- the regulator confirms the service exists.
        (o.sector = 'voluntary' and o.verification <> 'removed')
        or (o.sector <> 'voluntary' and o.verification = 'verified')
      )
      and (p_include_commercial or o.sector is distinct from 'commercial')
    group by o.id, o.name, o.category, o.sector, o.address, o.postcode,
             o.phone, o.website, o.lat, o.lng, o.location, h.g
    order by relevance desc, distance_m asc
    limit p_limit_places
  ),

  -- Layer 3: things to read, ring, or apply for. No location.
  advice as (
    select
      'advice'::text as layer,
      r.title as name,
      r.scope as detail,
      null::text as address,
      null::text as postcode,
      null::text as phone,
      r.url as website,
      null::double precision as lat,
      null::double precision as lng,
      null::int as distance_m,
      array_agg(rd.domain order by rd.confidence desc) as matched_domains,
      round(
        sum(rd.confidence)::numeric
        + case when r.scope = 'kent' then 0.5 else 0 end
      , 3) as relevance
    from resource r
    join resource_domain rd on rd.resource_id = r.id
    where rd.domain = any(p_domains)
      and r.verification = 'verified'
      and (p_include_commercial or r.provider_type is distinct from 'commercial')
    group by r.id, r.title, r.scope, r.url
    order by relevance desc, r.title
    limit p_limit_advice
  )

  select * from places
  union all
  select * from advice
  order by layer, relevance desc, distance_m asc nulls last;
$$;


-- ---------------------------------------------------------------------------
-- The honesty check.
--
-- For each domain the person scored badly on, how much did we actually find?
-- This is the query that tells you when the takeaway is failing someone, and
-- it should be surfaced to the product team, not buried.
--
-- A domain returning zero places is not a bug. It is the finding.
-- ---------------------------------------------------------------------------

create or replace function takeaway_summary(
  p_lat double precision,
  p_lng double precision,
  p_domains text[],
  p_radius_m int default 8000
)
returns table (
  domain text,
  places_nearby int,
  advice_available int,
  verdict text
)
language sql stable as $$
  with here as (
    select st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as g
  ),
  d as (select unnest(p_domains) as domain),
  p as (
    select dd.domain, count(distinct o.id)::int as n
    from d dd
    left join org_domain od on od.domain = dd.domain
    left join org o on o.id = od.org_id
      and o.location is not null
      and o.lat <> -999
      and o.takeaway_eligible
      and o.self_referable
      and (
        (o.sector = 'voluntary' and o.verification <> 'removed')
        or (o.sector <> 'voluntary' and o.verification = 'verified')
      )
      and st_dwithin(o.location, (select g from here), p_radius_m)
    group by dd.domain
  ),
  a as (
    select dd.domain, count(distinct r.id)::int as n
    from d dd
    left join resource_domain rd on rd.domain = dd.domain
    left join resource r on r.id = rd.resource_id
      and r.verification = 'verified'
    group by dd.domain
  )
  select
    p.domain,
    p.n as places_nearby,
    a.n as advice_available,
    case
      when p.n = 0 and a.n = 0 then 'NOTHING FOUND'
      when p.n = 0              then 'no local provision, advice only'
      when p.n < 3              then 'thin'
      else 'adequate'
    end as verdict
  from p join a on a.domain = p.domain
  order by p.n asc, p.domain;
$$;


-- ---------------------------------------------------------------------------
-- Try it. Faversham town centre, ME13 8NS, roughly 51.3157 / 0.8916.
-- ---------------------------------------------------------------------------

-- 1. Someone struggling with food and safety. The system should serve them well.
select layer, name, detail, distance_m, matched_domains
from takeaway(51.3157, 0.8916, array['food','safety']);

-- 2. Someone lonely and with nothing to do. The question this was all for.
select layer, name, detail, distance_m, matched_domains
from takeaway(51.3157, 0.8916, array['social','occupation']);

-- 3. And the honest scorecard for that same person.
select * from takeaway_summary(51.3157, 0.8916,
  array['control','personal_care','food','safety','social','occupation','accommodation','dignity']);
