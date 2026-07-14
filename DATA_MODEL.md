# Data model notes

## org
The core table. One row per organisation, from any source. Key columns beyond
the obvious:

- `sector` — statutory / health / voluntary / commercial / other. Note: CQC
  rows are all stamped `statutory` at ingest, which is not strictly accurate
  (many dentists/clinics are commercial). See "known wrong fields" below.
- `takeaway_eligible` — is this something to surface to a person screening at
  home. False for care homes, hospitals, substance misuse, grant trusts, etc.
- `self_referable` — can a member of the public approach directly, or does it
  need a professional referral.
- `relevance_checked` — has the AI relevance pass run (charities) or been set
  by the category map (CQC).
- `charity_number`, `income` — Charity Commission fields.
- `district` — filled by the geocode step from postcodes.io admin_district.
- `verification` — for CQC/advice this gates public visibility. For charities
  it does NOT gate the takeaway (see product decisions in README); a charity is
  surfaced on register + geocode, and the website link check only enriches.
- `lat = -999` — sentinel for a postcode that postcodes.io could not resolve.
  Filtered out of the takeaway.

## org_domain
Many-to-many, org to ASCOT domain, with a confidence and a method
(`manual` for the CQC category map, `ai` for charity tagging).

## resource / resource_domain
The advice layer. `resource` has no location; `scope` is 'national' or 'kent'.
Same domain-tag shape as org_domain.

## category_map / category_domain
The hand-curated CQC-category-to-ASCOT mapping. Thirty categories, each with an
eligibility + self-referable decision and a set of domains. Applied to org in
sql/05. This replaced a per-row AI pass because every CQC row is one of ~30
categories — thirty decisions, not 4,000.

## The two query functions

### takeaway(lat, lng, domains[, radius_m, limit_places, limit_advice, include_commercial])
Returns places (CQC + voluntary, merged and ranked by relevance minus distance)
and advice (national + Kent), for the domains supplied. This is what a client
calls after a completed screen.

### takeaway_summary(lat, lng, domains[, radius_m])
The honesty check. Per domain: how many places nearby, how much advice, and a
verdict (NOTHING FOUND / advice only / thin / adequate). Surface this to the
product team — a domain returning nothing is the finding, not a bug to hide.

## Known wrong fields (unfixed, on purpose)

- `org.sector` is `statutory` on every CQC row. Fixing it rewrites ~4,300 rows;
  `category_map.correct_sector` holds the right value ready to apply.
- `org.districts` (the array) holds only 'Kent'/'Medway' on CQC rows. The newer
  `org.district` (text, from geocoding) is the accurate one — prefer it.
