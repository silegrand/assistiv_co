# Kent + Medway Support Directory

A three-layer, ASCOT-tagged, geocoded directory that turns a completed ASCOT
screening into a ranked list of local support a person can act on.

Built for Assistiv Systems. Covers Kent and Medway. Data sources are open
(CQC, Charity Commission, KCC signposting); the tagging, routing and scoring
are the original work.

## What it does

A person completes the ASCOT screen, gives a postcode, and the domains they
scored poorly on. The system returns:

- **Places** they can go: CQC-registered services and voluntary organisations
  near them, filtered to those they can self-refer to and that are appropriate
  to surface, ranked by relevance and distance.
- **Advice**: national and Kent-specific pages, helplines and schemes, tagged
  to the same domains.
- **An honesty scorecard** (`takeaway_summary`) that reports, per domain, how
  much was actually found — including when the answer is "nothing".

## The three layers

| Layer | Source | Rows (approx) | Nature |
|-------|--------|---------------|--------|
| Statutory / commercial care | CQC register | 4,361 | Regulated services. Strong on personal care, food, safety, accommodation. Almost nothing on social participation or occupation. |
| Voluntary | Charity Commission register (area of operation = Kent/Medway) | 5,013 loaded, ~832 takeaway-eligible | Community groups, associations, activity charities. Strong exactly where CQC is weak. |
| Advice | KCC BetterCare signposting list | 94 | Pages, helplines, schemes. No location. |

The central finding: the regulated care system is structurally empty on the
two domains (social participation, occupation) where a person below the Care
Act threshold actually declines. The voluntary layer fills that gap. The
combined takeaway serves all eight domains.

## Architecture

- **Supabase** (Postgres + PostGIS) holds everything. Tables: `org`,
  `org_source`, `org_domain`, `ingest_state`, `resource`, `resource_domain`,
  plus a `category_map` for CQC category tagging.
- **A single Cloudflare Worker** (`worker/cqc-ingest-worker.js`) runs all
  ingestion as steps against `/ingest`, and on a cron.
- **Two query functions** (`takeaway`, `takeaway_summary`) are what a client
  calls after a completed screen.

## Run order

Run the SQL files in `sql/` in numeric order in the Supabase SQL editor.
Deploy the Worker, then drain its steps.

```
sql/00_base_schema.sql            core tables + types
sql/01_schema_resources.sql       advice layer tables + takeaway_resources()
sql/02_seed_resources.sql         94 advice rows, hand-tagged
sql/03_fix_resource_checks.sql    resource check_attempts column
sql/04_add_tag_attempts.sql       org tag_attempts column
sql/05_category_tagging.sql       CQC category -> ASCOT map, applied to org
sql/06_prereq_geocode_ctag.sql    district + relevance_checked columns
sql/07a_create_stage.sql          charity staging table
   -> import scripts/kent_charities.csv into charity_stage via Table Editor
sql/07c_load_from_stage.sql       move charities into org, deduped
sql/08_exclude_substance_misuse.sql   product decision: exclude from takeaway
sql/09_requeue_tagged_charities.sql   (only if re-tagging a prior run)
sql/10_takeaway.sql               the two takeaway functions
sql/11_eligibility_review.sql     review queries for false positives
sql/12_provision_type.sql         venue vs service split (rule-based first pass)
sql/13_prereq_refine.sql          columns for the audience-refinement pass
sql/14_reconcile_eligibility.sql  fix false exclusions; flag venues as leads
sql/15_kent_gap_map.sql           Kent-scoped provision gap map + views
```

Worker step for the audience-refinement pass (after ctag):
```
/ingest?step=refine&n=8           AI pass: is this for isolated older people;
                                  service vs venue. Sets older_people_relevant.
```

See `docs/FINDINGS_provision_gap.md` for what the gap map found and, more
importantly, what it does and does not license as a decision.

Worker steps, drained from a browser console on the Worker's own domain
(never run a manual loop and the cron simultaneously — `ingest_state.pending`
is a single JSONB array and overlapping writes clobber):

```
/ingest?step=seed                 build the CQC location queue
/ingest?step=locations&n=8        drain locations into org
/ingest?step=tag&n=8              (legacy CQC tagger — superseded by category map)
/ingest?step=geocode&n=45         fill lat/lng + district from postcode (postcodes.io)
/ingest?step=ctag&n=8             AI relevance + ASCOT tagging for charities
/ingest?step=links&n=15           verify advice + charity websites
/ingest                           status of all layers
```

`n` is capped by Cloudflare's 50-subrequest-per-invocation limit. Geocode
patches per row, so keep n <= 45. Charity tagging is one Anthropic call each;
parallelism comes from running several browser loops at once, not from raising
n. Six concurrent loops was the working ceiling on a standard Anthropic tier;
twelve triggered rate-limit failures.

## Environment (Worker secrets)

```
CQC_KEY                CQC subscription key
SUPABASE_URL           https://<project>.supabase.co
SUPABASE_SERVICE_KEY   Supabase service-role key
ANTHROPIC_KEY          sk-ant-...
```

## Known limitations

These are real and should be stated plainly to any partner or commissioner.

1. **Charity geocoding is by registered contact address, not activity venue.**
   A charity that runs a lunch club in one town may be registered to a
   trustee's home or an accountant's office elsewhere. For small local
   charities the two usually coincide; for some they do not. Fixing this
   requires activity-level location data — the reason for the KCC / voluntary-
   sector-infrastructure conversations. This is the single biggest gap.

2. **Tagging has occasional false positives.** The AI relevance pass is good
   but not perfect (e.g. a care provider or a buildings-preservation trust may
   slip through as "social/occupation"). Before any patient-facing use, the
   eligible set needs a human review pass. Signposting a frail person to the
   wrong thing is a safety issue, not a data-quality footnote.

3. **The data is open, not proprietary.** CQC and Charity Commission data are
   available to anyone. The asset is the tagging, routing and scoring method,
   not the underlying rows.

4. **Kent and Medway only.** The pipeline generalises to any county, but this
   is one proof, not a national product.

## Product decisions on record

- **Care homes, hospitals, ambulance stations excluded from the takeaway.**
  Real, in the database, not surfaced to someone screening at home. Not an
  action a person living independently can take.
- **Substance misuse services excluded from the takeaway.** Inappropriate to
  surface to an older adult completing a preventative wellbeing screen.
- **Faith-based sponsorship does not make a charity ineligible.** Judged on the
  service, not the sponsor.
- **Charities surface on register + geocode; a live website is not required.**
  A registered charity with a phone but no website is not "unverified" in any
  real sense, and gating on a website would hide the smallest, most local
  groups — exactly the ones the cohort most needs.

## Data provenance and licensing

- CQC location data: CQC public API, Open Government Licence.
- Charity data: Charity Commission full register extract, Open Government
  Licence. Attribution required.
- Advice layer: derived from KCC's public BetterCare signposting list.
- Postcode geocoding: postcodes.io (ONS data, OGL).

Attribute OGL sources per the licence in any published or client-facing use.
