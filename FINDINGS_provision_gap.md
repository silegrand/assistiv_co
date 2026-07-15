# Findings: Kent & Medway provision gap (POC)

Internal note for Assistiv. Written from the data as it stood after the
eligibility review and audience-refinement pass. Read this before any build or
expansion discussion — it is the honest version, caveats included.

## Headline

Kent and Medway have **198 confirmed voluntary services for older people** that
a person can self-refer to. Tagged against the eight ASCOT domains, they are
distributed sharply unevenly:

| Domain | Services | % of providers |
|--------|----------|----------------|
| Social participation | 172 | 87% |
| Occupation | 149 | 75% |
| Control | 125 | 63% |
| Dignity | 120 | 61% |
| Safety | 47 | 24% |
| Food | 43 | 22% |
| Personal care | 17 | 9% |
| Accommodation | 16 | 8% |

## What this overturns

The assumption at the start was that the system has little for isolated older
people. The opposite is true. The voluntary sector is **connection-rich**:
social participation, occupation, control and dignity are well covered. Someone
lonely with time to fill has real options.

The genuine gap is the **practical, at-home, physical cluster**: personal care,
accommodation, food, safety. This is the person who is physically declining —
struggling to wash, cook, keep the home safe — rather than simply isolated.

## The build hypothesis this suggests

The voluntary sector already does connection and activity. The unmet need
Assistiv could address is **practical daily-living support for older people who
are declining physically but sit below the social-care eligibility threshold**.
That need sits directly alongside Assistiv's preventative-care positioning.

This is a hypothesis to test, not a decision. See caveats.

## Caveats — do not skip these

1. **Voluntary only.** Personal care shows 17 because CQC-registered domiciliary
   care (which does personal care) was correctly excluded from the takeaway as
   not self-referable. "17" means self-referable *voluntary* personal-care
   support, not all personal care in Kent. The paid/commissioned world is
   larger. For a build decision this distinction is decisive.

2. **Supply only, no demand yet.** This is the supply half of a gap map. A gap
   is only an opportunity where thin supply meets real demand. Demand — where
   people actually screen badly, by domain and place — arrives once the ASCOT
   tool is live. Until then this shows where provision is thin, not where it is
   thin *and needed*.

3. **Register-address geocoding.** County totals are clean. District-level
   figures are not fully trustworthy: charities are geocoded to their
   registered contact address, so county towns (Maidstone, Tunbridge Wells)
   over-count because charities register there while operating elsewhere. Before
   choosing a district to build in, the district figures need a confirming
   manual sweep against the KCC directory.

4. **Not the last word on what exists.** The directory is built from CQC and the
   Charity Commission register. Unregistered community groups (many lunch clubs,
   informal befriending) are invisible to both. More sweeps — KCC directory,
   voluntary-sector infrastructure bodies — are needed before any "nothing here"
   is trusted. The `low_data` / visibility flags in the gap map exist to stop a
   data blind spot being read as a real desert.

## How to read the gap map

`sql/15_kent_gap_map.sql` builds, scoped to the twelve Kent + Medway districts:

- `v_kent_domain_totals` — the clean county picture above.
- `provision_gap_map()` — district × domain, confirmed services + venue leads +
  a visibility flag.
- `v_kent_gaps` — empty cells, split into `activate_venue` (a room exists,
  needs a programme — the cheap opportunity) vs `build_from_scratch`, flagged
  for trust.

The honest use is: the map tells you *where to look*, confirmed by a sweep, not
*where to build*.

## Provision counts, for the record

- 198 confirmed services (older-people-relevant, self-referable, geocoded).
- 331 venue leads (halls, centres — may host relevant activity, unconfirmed).
- 241 excluded (worship-only, wrong audience, grant-only, unclear).
- From 5,013 Kent/Medway charities loaded, refined down through eligibility and
  audience passes. Each step traded an inflated number for a true one.
