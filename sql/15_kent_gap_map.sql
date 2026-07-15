-- ---------------------------------------------------------------------------
-- PROVISION GAP MAP v2 — scoped to Kent + Medway only.
--
-- v1 leaked ~140 non-Kent districts, because charities are geocoded to their
-- registered contact address, and many that OPERATE in Kent are ADMINISTERED
-- elsewhere (Birmingham, Isle of Wight, etc). Those are noise for a Kent POC.
-- This version hard-restricts to the twelve Kent + Medway districts.
--
-- Caveat that still stands WITHIN Kent: a charity registered in a county town
-- (Maidstone, Tunbridge Wells) but operating in a village is counted in the
-- county town. So high counts there may be partly a head-office effect. Treat
-- the map as "where to look", confirmed by a manual sweep, not "where to build".
-- ---------------------------------------------------------------------------

-- The twelve. Kent County Council's districts plus Medway unitary.
create or replace function kent_districts() returns text[]
language sql immutable as $$
  select array[
    'Ashford','Canterbury','Dartford','Dover','Folkestone and Hythe',
    'Gravesham','Maidstone','Sevenoaks','Swale','Thanet',
    'Tonbridge and Malling','Tunbridge Wells','Medway'
  ]
$$;

create or replace function provision_gap_map()
returns table (
  district text,
  domain text,
  services int,
  leads int,
  visibility text
)
language sql stable as $$
  with districts as (
    select unnest(kent_districts()) as district
  ),
  domains as (
    select unnest(array[
      'control','personal_care','food','safety',
      'social','occupation','accommodation','dignity'
    ]) as domain
  ),
  grid as (
    select d.district, dm.domain from districts d cross join domains dm
  ),
  svc as (
    select o.district, od.domain, count(distinct o.id) as n
    from org o
    join org_domain od on od.org_id = o.id
    where o.sector = 'voluntary' and o.takeaway_eligible
      and o.provision_type = 'service'
      and o.lat is not null and o.lat <> -999
      and o.district = any(kent_districts())
    group by o.district, od.domain
  ),
  led as (
    select o.district, od.domain, count(distinct o.id) as n
    from org o
    join org_domain od on od.org_id = o.id
    where o.sector = 'voluntary' and o.is_lead
      and o.district = any(kent_districts())
    group by o.district, od.domain
  ),
  dist_total as (
    select o.district, count(distinct o.id) as n
    from org o
    where o.sector = 'voluntary' and o.takeaway_eligible
      and o.provision_type = 'service'
      and o.district = any(kent_districts())
    group by o.district
  )
  select
    g.district, g.domain,
    coalesce(svc.n,0)::int, coalesce(led.n,0)::int,
    case when coalesce(dt.n,0) >= 8 then 'ok' else 'low_data' end
  from grid g
  left join svc on svc.district=g.district and svc.domain=g.domain
  left join led on led.district=g.district and led.domain=g.domain
  left join dist_total dt on dt.district=g.district
  order by g.district, g.domain;
$$;


-- ---------------------------------------------------------------------------
-- COUNTY VIEW: total confirmed services per domain across all of Kent+Medway.
-- This is the headline gap picture, uncontaminated by which district a charity
-- happens to register in.
-- ---------------------------------------------------------------------------
create or replace view v_kent_domain_totals as
select
  od.domain,
  count(distinct o.id) as services,
  round(100.0 * count(distinct o.id) /
        nullif((select count(distinct o2.id) from org o2
                where o2.sector='voluntary' and o2.takeaway_eligible
                  and o2.provision_type='service'
                  and o2.district = any(kent_districts())),0), 1) as pct_of_services
from org o
join org_domain od on od.org_id = o.id
where o.sector='voluntary' and o.takeaway_eligible
  and o.provision_type='service'
  and o.district = any(kent_districts())
group by od.domain
order by services desc;


-- ---------------------------------------------------------------------------
-- THE BUILD SIGNAL: district x domain cells with zero confirmed services.
-- Split by whether venue leads exist (cheaper: activate a room) or not
-- (build from scratch), and flagged for trust.
-- ---------------------------------------------------------------------------
create or replace view v_kent_gaps as
select district, domain, leads,
  case when leads > 0 then 'activate_venue' else 'build_from_scratch' end as route,
  visibility
from provision_gap_map()
where services = 0
order by visibility, leads desc, district, domain;


-- ---------------------------------------------------------------------------
-- Read them.
-- ---------------------------------------------------------------------------
select * from v_kent_domain_totals;
-- select * from provision_gap_map();
-- select * from v_kent_gaps;
