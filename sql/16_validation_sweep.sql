-- ---------------------------------------------------------------------------
-- VALIDATION SWEEP
--
-- Purpose: find out how much to trust the gap map. We test the two failure
-- modes deliberately, not random cells.
--
--   Test A (false gap / register-address emptying): a district the map says has
--   ZERO services in a domain. Is that real, or are there services that operate
--   there but register elsewhere? Check against the KCC directory by hand.
--
--   Test B (false provision / register-address inflating): the actual named
--   services the map credits to a county town. Do they really operate there, or
--   are they county-wide charities that just have their office there?
--
-- The gap between "what the map claims" and "what a 10-minute KCC directory
-- search finds" is the tool's error rate. That number decides decision-grade
-- vs demo-grade.
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- TEST A: FALSE GAPS
-- Pick 3 district x domain cells the map calls empty. Personal care and food
-- are the interesting ones (the claimed gap). We list the EMPTY cells in the
-- larger districts, where a true zero is least likely and so most worth testing.
-- ===========================================================================
select district, domain, leads, route, visibility
from v_kent_gaps
where domain in ('personal_care','food','accommodation','safety')
  and visibility = 'ok'          -- only where we claim the zero is trustworthy
order by district, domain;

-- For each of ~3 chosen cells, the manual step is:
--   1. Go to kent.connecttosupport.org or local.kent.gov.uk
--   2. Search that district + that need (e.g. "meals Dartford", "help washing Thanet")
--   3. Count how many self-referable services for older people you find that
--      are NOT care homes / domiciliary agencies.
--   If the map said 0 and you find 3, that cell is a false gap.


-- ===========================================================================
-- TEST B: FALSE PROVISION
-- The map credits Maidstone and Tunbridge Wells with the most social/occupation
-- services. List them by name + postcode so you can check: does this charity
-- actually run something IN this district, or is it a county-wide body with an
-- office here.
-- ===========================================================================
select o.name, o.postcode, o.district,
       o.phone, o.website,
       left(o.description, 90) as activities,
       array_agg(od.domain order by od.domain) as domains
from org o
join org_domain od on od.org_id = o.id
where o.sector = 'voluntary' and o.takeaway_eligible
  and o.provision_type = 'service'
  and o.district = 'Maidstone'
  and od.domain in ('social','occupation')
group by o.id, o.name, o.postcode, o.district, o.phone, o.website, o.description
order by o.name;

-- Read the names. A "Kent-wide" or "..Kent.." charity registered in Maidstone
-- that actually serves the whole county is a partial false-attribution: it
-- inflates Maidstone and empties the districts it also serves. Count how many
-- of the list look genuinely Maidstone-specific vs county-wide.


-- ===========================================================================
-- TEST C: quick reconciliation — how many services have a Kent contact at all
-- vs how many were pinned outside Kent (the ones we already know are noise).
-- Sanity on how big the register-address problem is overall.
-- ===========================================================================
select
  case when district = any(kent_districts()) then 'kent_registered'
       else 'registered_outside_kent' end as where_registered,
  count(*) as services
from org
where sector = 'voluntary' and takeaway_eligible and provision_type = 'service'
group by 1;
