-- ---------------------------------------------------------------------------
-- takeaway_by_domain
--
-- The per-domain version. For each domain the person flagged, return the
-- nearest confirmed services, plus a stepped-radius failover so a thin area
-- still gets its closest option rather than nothing.
--
-- For each domain, independently:
--   1. look within 8km. If found, band = 'local'.
--   2. else within 15km, band = 'nearby'.
--   3. else within 40km, band = 'distant'  (honestly labelled as a reach).
--   4. else nothing local -> the caller shows the national advice layer.
--
-- The band lets the tool tell the truth: "near you" vs "the closest we found,
-- X miles away" vs "nothing local, here is national support". Never dresses a
-- 30-mile service as local.
--
-- Returns plain_summary so the tool can show a human sentence per service.
--
-- Run after 23_prereq_summarise.sql and the summarise pass.
-- ---------------------------------------------------------------------------

create or replace function takeaway_by_domain(
  p_lat double precision,
  p_lng double precision,
  p_domains text[],
  p_per_domain int default 4,
  p_include_commercial boolean default false
)
returns table (
  domain text,
  band text,                 -- 'local' | 'nearby' | 'distant'
  name text,
  detail text,
  plain_summary text,
  address text,
  postcode text,
  phone text,
  website text,
  lat double precision,
  lng double precision,
  distance_m int,
  relevance numeric
)
language sql stable as $$
  with here as (
    select st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as g
  ),
  wanted as (
    select unnest(p_domains) as domain
  ),
  -- every eligible service that matches a wanted domain, with its distance,
  -- regardless of radius (we band afterwards)
  candidates as (
    select
      od.domain,
      o.id,
      o.name,
      coalesce(o.category, initcap(o.sector::text)) as detail,
      o.plain_summary,
      o.address, o.postcode, o.phone, o.website, o.lat, o.lng,
      round(st_distance(o.location, h.g))::int as distance_m,
      od.confidence
    from wanted w
    join org_domain od on od.domain = w.domain
    join org o on o.id = od.org_id
    cross join here h
    where o.location is not null
      and o.lat <> -999
      and o.takeaway_eligible
      and o.self_referable
      and (
        (o.sector = 'voluntary' and o.verification <> 'removed')
        or (o.sector <> 'voluntary' and o.verification = 'verified')
      )
      and (p_include_commercial or o.sector is distinct from 'commercial')
      and o.provision_type = 'service'
  ),
  banded as (
    select *,
      case
        when distance_m <= 8000  then 'local'
        when distance_m <= 15000 then 'nearby'
        when distance_m <= 40000 then 'distant'
        else 'toofar'
      end as band
    from candidates
  ),
  -- the best band that actually has results, per domain
  best_band as (
    select domain,
      min(case band
        when 'local' then 1 when 'nearby' then 2
        when 'distant' then 3 else 4 end) as rank
    from banded
    where band <> 'toofar'
    group by domain
  ),
  ranked as (
    select b.*,
      row_number() over (
        partition by b.domain
        order by b.distance_m asc, b.confidence desc
      ) as rn
    from banded b
    join best_band bb on bb.domain = b.domain
      and (case b.band
            when 'local' then 1 when 'nearby' then 2
            when 'distant' then 3 else 4 end) = bb.rank
    where b.band <> 'toofar'
  )
  select
    domain, band, name, detail, plain_summary,
    address, postcode, phone, website, lat, lng, distance_m,
    round(confidence,2) as relevance
  from ranked
  where rn <= p_per_domain
  order by
    domain,
    case band when 'local' then 1 when 'nearby' then 2 else 3 end,
    distance_m;
$$;


-- ---------------------------------------------------------------------------
-- takeaway_advice_by_domain
-- The national + Kent advice layer, per domain, for the fallback and for the
-- "information and helplines" section under each area.
-- ---------------------------------------------------------------------------
create or replace function takeaway_advice_by_domain(
  p_domains text[],
  p_per_domain int default 4
)
returns table (
  domain text,
  name text,
  url text,
  scope text
)
language sql stable as $$
  with wanted as (select unnest(p_domains) as domain),
  ranked as (
    select
      rd.domain, r.title as name, r.url, r.scope,
      row_number() over (
        partition by rd.domain
        order by (case when r.scope='kent' then 0 else 1 end), rd.confidence desc
      ) as rn
    from wanted w
    join resource_domain rd on rd.domain = w.domain
    join resource r on r.id = rd.resource_id
    where r.verification = 'verified'
      and r.provider_type is distinct from 'commercial'
  )
  select domain, name, url, scope
  from ranked where rn <= p_per_domain
  order by domain, scope;
$$;

grant execute on function takeaway_by_domain(
  double precision, double precision, text[], int, boolean
) to service_role;
grant execute on function takeaway_advice_by_domain(text[], int) to service_role;

notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- Try it: Faversham, food + social + occupation.
-- select domain, band, name, plain_summary, distance_m
-- from takeaway_by_domain(51.3157, 0.8916, array['food','social','occupation']);
-- ---------------------------------------------------------------------------
