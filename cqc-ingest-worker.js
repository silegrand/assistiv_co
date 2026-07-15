/*
  Kent + Medway ingest Worker.
  CQC locations -> Supabase, ASCOT-domain tagging, and advice-layer link checking.
  Runtime: Cloudflare Worker. Paste this whole file into the Worker editor.

  ---------------------------------------------------------------------------
  CHANGES FROM THE PREVIOUS VERSION
  ---------------------------------------------------------------------------
  1. FIXED, DATA LOSS. processLocations() previously computed `rest` before the
     loop and wrote it back unconditionally, so any location that threw (CQC
     429, timeout, transient 500) was dropped from the queue and never retried,
     despite a comment claiming otherwise. Failures are now requeued.

  2. FIXED, INFINITE TAG LOOP. processTags() returned the number of orgs
     *fetched*, not the number successfully tagged, so a caller stopping on
     `tagged === 0` never stopped. It now returns real counts, and an org whose
     Anthropic call keeps failing is retired after MAX_TAG_ATTEMPTS instead of
     being re-selected on every pass forever.

  3. NEW, LINK CHECKING. processLinks() verifies each row in the `resource`
     table actually resolves before it becomes publicly readable, and re-checks
     on a schedule so dead links are withdrawn rather than served.

  4. NOT CHANGED, DELIBERATELY. `sector` is still hardcoded to 'statutory' on
     every CQC row, and `districts` still holds 'Kent' or 'Medway' rather than
     the twelve real districts. Both are wrong. Both would rewrite rows you
     already have, so I have left them alone pending your say-so. See the note
     at the foot of this file.

  ---------------------------------------------------------------------------
  SUPABASE PREREQUISITE, run once in the SQL editor before deploying:
  ---------------------------------------------------------------------------
    alter table org add column if not exists tag_attempts int not null default 0;

  (Plus 01_schema_resources.sql and 02_seed_resources.sql for the advice layer.)

  ---------------------------------------------------------------------------
  WORKER ENV VARS (Settings -> Variables, all as secrets):
    CQC_KEY               CQC subscription key
    SUPABASE_URL          https://<project>.supabase.co
    SUPABASE_SERVICE_KEY  Supabase service-role key
    ANTHROPIC_KEY         sk-ant-...
  ---------------------------------------------------------------------------
  ENDPOINTS
    /ingest                        progress
    /ingest?step=seed              rebuild the Kent+Medway location queue
    /ingest?step=locations&n=8     process a batch of CQC locations
    /ingest?step=tag&n=8           tag a batch of untagged orgs
    /ingest?step=links&n=15        link-check a batch of resources
  ---------------------------------------------------------------------------
  IMPORTANT: `ingest_state.pending` is a single JSONB array, read-modify-write.
  Two overlapping invocations will clobber each other. Do NOT run a browser
  drain loop and a cron trigger at the same time. Pick one.
  ---------------------------------------------------------------------------
*/

const CQC_BASE         = 'https://api.service.cqc.org.uk/public/v1';
const LAS              = ['Kent', 'Medway'];
const DOMAINS          = ['control','personal_care','food','safety','social','occupation','accommodation','dignity'];
const AI_MODEL         = 'claude-sonnet-5';

const LOC_BATCH        = 8;    // ~4 subrequests each
const TAG_BATCH        = 8;    // ~3 subrequests each
const LINK_BATCH       = 15;   // 2 subrequests each
const MAX_TAG_ATTEMPTS = 3;    // retire an org after this many failed tag calls
const RESOURCE_TTL_MS  = 30 * 24 * 3600 * 1000;  // re-check advice links monthly

// ---- Supabase REST helpers ----
function sbHeaders(env, extra = {}) {
  // Key goes in the apikey header only. This works with both the legacy
  // service_role JWT and the newer sb_secret_ key, which is not a JWT and must
  // not be sent as a Bearer token. The gateway resolves the service role from
  // apikey and bypasses row-level security.
  return {
    apikey: env.SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
    ...extra
  };
}

async function sbGet(env, path) {
  const r = await fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, { headers: sbHeaders(env) });
  if (!r.ok) throw new Error(`Supabase GET ${r.status}: ${await r.text()}`);
  return r.json();
}

async function sbPost(env, table, body, prefer) {
  return fetch(`${env.SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST',
    headers: sbHeaders(env, prefer ? { Prefer: prefer } : {}),
    body: JSON.stringify(body)
  });
}

async function sbPatch(env, table, query, body) {
  return fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'PATCH',
    headers: sbHeaders(env),
    body: JSON.stringify(body)
  });
}

// Count rows without dragging them across the wire.
//
// This previously read content-range without checking whether the request had
// succeeded, so any PostgREST error fell through to `|| 0`. A count that could
// not be computed was indistinguishable from a count that was genuinely zero,
// and the status endpoint cheerfully reported "untagged: 0" while no org had
// ever been tagged. It now throws, so a broken count surfaces as an error
// rather than as good news.
async function sbCount(env, table, query) {
  const r = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}&select=id`, {
    method: 'HEAD',
    headers: sbHeaders(env, { Prefer: 'count=exact' })
  });

  if (!r.ok) {
    throw new Error(`Supabase COUNT ${r.status} on ${table}?${query}`);
  }

  const range = r.headers.get('content-range');   // e.g. "0-24/1234"
  if (!range || !range.includes('/')) {
    throw new Error(`Supabase COUNT on ${table}?${query}: no content-range header`);
  }

  const total = range.split('/')[1];
  if (total === '*') return null;

  const n = parseInt(total, 10);
  if (Number.isNaN(n)) {
    throw new Error(`Supabase COUNT on ${table}?${query}: unparseable range "${range}"`);
  }
  return n;
}

// ---- CQC helper ----
async function cqc(env, path) {
  // The current CQC API identifies the caller by subscription key and rejects
  // unrecognised query parameters, so partnerCode is deliberately not sent.
  const base = env.CQC_BASE || CQC_BASE;
  const r = await fetch(`${base}${path}`, {
    headers: { 'Ocp-Apim-Subscription-Key': env.CQC_KEY }
  });
  if (!r.ok) {
    const body = await r.text().catch(() => '');
    throw new Error(`CQC ${r.status} on ${path} :: ${body.slice(0, 400)}`);
  }
  return r.json();
}

// ---- Step 1: build the queue of location ids for both authorities ----
async function seed(env) {
  let ids = [];
  for (const la of LAS) {
    let page = 1, totalPages = 1;
    do {
      const j = await cqc(env, `/locations?localAuthority=${encodeURIComponent(la)}&page=${page}&perPage=1000`);
      totalPages = j.totalPages || 1;
      (j.locations || []).forEach(l => ids.push(l.locationId));
      page++;
    } while (page <= totalPages);
  }
  ids = [...new Set(ids)];

  await sbPost(env, 'ingest_state?on_conflict=id', {
    id: 'cqc',
    pending: ids,
    seen: ids.length,
    upserted: 0,
    last_seed: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }, 'resolution=merge-duplicates');

  return ids.length;
}

// ---- Step 2: process a batch of locations into org + org_source ----
async function processLocations(env, n) {
  const rows = await sbGet(env, 'ingest_state?id=eq.cqc&select=pending,upserted');
  if (!rows.length) return { done: 0, failed: 0, remaining: 0 };

  const pending = rows[0].pending || [];
  const batch   = pending.slice(0, n);
  const rest    = pending.slice(n);
  let upserted  = rows[0].upserted || 0;

  const failed = [];

  for (const id of batch) {
    try {
      const loc = await cqc(env, `/locations/${encodeURIComponent(id)}`);
      await upsertLocation(env, loc);
      upserted++;
    } catch (e) {
      // FIX: requeue rather than silently drop. Pushed to the back so a
      // permanently broken id cannot wedge the head of the queue.
      failed.push(id);
    }
  }

  const nextPending = [...rest, ...failed];

  await sbPatch(env, 'ingest_state', 'id=eq.cqc', {
    pending: nextPending,
    upserted,
    updated_at: new Date().toISOString()
  });

  return {
    done: batch.length - failed.length,
    failed: failed.length,
    remaining: nextPending.length
  };
}

async function upsertLocation(env, loc) {
  const id = loc.locationId;

  const fields = {
    name: loc.name,
    sector: 'statutory',   // see note at foot of file: this is wrong, and unchanged on purpose
    category: (loc.gacServiceTypes && loc.gacServiceTypes[0] && loc.gacServiceTypes[0].name) || loc.type || null,
    address: [loc.postalAddressLine1, loc.postalAddressLine2, loc.postalAddressTownCity].filter(Boolean).join(', ') || null,
    postcode: loc.postalCode || null,
    lat: typeof loc.onspdLatitude  === 'number' ? loc.onspdLatitude  : null,
    lng: typeof loc.onspdLongitude === 'number' ? loc.onspdLongitude : null,
    phone: loc.mainPhoneNumber || null,
    website: loc.website || null,
    districts: loc.localAuthority ? [loc.localAuthority] : [],   // also wrong, also unchanged on purpose
    primary_source: 'CQC',
    source_url: `https://www.cqc.org.uk/location/${id}`,
    last_verified: new Date().toISOString(),
    verification: 'verified',
    updated_at: new Date().toISOString()
  };

  const existing = await sbGet(
    env,
    `org_source?source=eq.CQC&source_id=eq.${encodeURIComponent(id)}&select=org_id`
  );

  if (existing.length) {
    const orgId = existing[0].org_id;
    await sbPatch(env, 'org', `id=eq.${orgId}`, fields);
    await sbPatch(
      env,
      'org_source',
      `source=eq.CQC&source_id=eq.${encodeURIComponent(id)}`,
      { raw: loc, fetched_at: new Date().toISOString() }
    );
  } else {
    const res = await sbPost(env, 'org', fields, 'return=representation');
    if (!res.ok) throw new Error(`org insert ${res.status}: ${await res.text()}`);
    const created = await res.json();
    const orgId = created[0].id;
    await sbPost(env, 'org_source', {
      org_id: orgId,
      source: 'CQC',
      source_id: id,
      source_url: fields.source_url,
      raw: loc,
      fetched_at: new Date().toISOString()
    });
  }
}

// ---- Step 3: tag untagged orgs to ASCOT domains via Anthropic ----
async function processTags(env, n) {
  const orgs = await sbGet(
    env,
    `org?tagged=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}` +
    `&select=id,name,category,description,tag_attempts&order=created_at.asc&limit=${n}`
  );

  let tagged = 0, failed = 0;

  for (const o of orgs) {
    try {
      const domains = await tagOrg(env, o);

      if (domains.length) {
        const rows = domains.map(d => ({
          org_id: o.id,
          domain: d.domain,
          confidence: d.confidence,
          method: 'ai',
          model: AI_MODEL
        }));
        await sbPost(env, 'org_domain?on_conflict=org_id,domain', rows, 'resolution=merge-duplicates');
      }

      // A genuine empty result is still a completed tag. An org with no domains
      // is findable later as: tagged = true, and no rows in org_domain.
      await sbPatch(env, 'org', `id=eq.${o.id}`, { tagged: true });
      tagged++;
    } catch (e) {
      // FIX: count the attempt, so a row that always fails is retired instead
      // of being re-selected on every pass for ever.
      await sbPatch(env, 'org', `id=eq.${o.id}`, {
        tag_attempts: (o.tag_attempts || 0) + 1
      });
      failed++;
    }
  }

  const remaining = await sbCount(
    env, 'org', `tagged=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`
  );

  return { tagged, failed, remaining };
}

async function tagOrg(env, o) {
  const system =
    'You tag UK support organisations against the eight ASCOT domains: ' +
    'control (control over daily life), personal_care (personal cleanliness and comfort), ' +
    'food (food and drink), safety (personal safety), social (social participation), ' +
    'occupation (how time is spent), accommodation (accommodation comfort), dignity. ' +
    'Given an organisation, return ONLY a JSON array of the domains it plausibly helps with, ' +
    'each item {"domain":"<key>","confidence":0-1}. Use only the listed keys. ' +
    'Do not invent services beyond what the text supports. If unclear, return [].';

  const user = `Name: ${o.name}\nCategory: ${o.category || 'unknown'}\nDescription: ${o.description || 'none'}`;

  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ANTHROPIC_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: AI_MODEL,
      max_tokens: 300,
      system,
      messages: [{ role: 'user', content: user }]
    })
  });

  const data = await r.json();
  if (data.error) throw new Error(data.error.message);

  const text  = (data.content || []).map(c => c.text || '').join('');
  const clean = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  let arr;
  try { arr = JSON.parse(clean); } catch (e) { return []; }

  return Array.isArray(arr) ? arr.filter(x => DOMAINS.includes(x.domain)) : [];
}

// ---- Step 4: link-check the advice layer ----
//
// The first version of this was wrong and condemned 7 of the first 15 links.
// It treated any non-2xx/3xx as dead, which conflates three very different
// things:
//
//   404 / 410      the page is genuinely gone.          -> removed
//   401 / 403 /429 the server exists and is refusing    -> alive, but bot-blocked
//                  to talk to an unidentified bot.
//   0 / 5xx        we could not reach it this time.     -> inconclusive, retry
//
// Only the first of those justifies withdrawing a link from someone's takeaway.
// A gov.uk page that 403s a headless fetch is not a dead page, and hiding the
// Winter Fuel Payment from an older person because Akamai did not like our
// User-Agent would be a worse failure than showing nothing at all.
//
// We also send a real User-Agent and use GET, not HEAD, because a meaningful
// number of servers handle HEAD badly.

const UA = 'AssistivLinkCheck/1.0 (+https://assistiv.co; preventative care directory)';

const GONE      = [404, 410];
const BOT_BLOCK = [401, 403, 429];

async function checkOne(url) {
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      headers: {
        'User-Agent': UA,
        'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
        'Accept-Language': 'en-GB,en;q=0.9'
      }
    });
    return res.status;
  } catch (e) {
    return 0;   // DNS failure, timeout, TLS failure
  }
}

async function processLinks(env, n) {
  const rows = await sbGet(
    env,
    `resource?verification=in.(unverified,stale)&check_attempts=lt.3` +
    `&select=id,url,check_attempts&order=created_at.asc&limit=${n}`
  );

  let alive = 0, gone = 0, blocked = 0, inconclusive = 0;

  for (const r of rows) {
    const status = await checkOne(r.url);

    let verification;
    if (status >= 200 && status < 400) {
      verification = 'verified';  alive++;
    } else if (GONE.includes(status)) {
      verification = 'removed';   gone++;
    } else if (BOT_BLOCK.includes(status)) {
      // The server answered. It exists. It simply will not serve a bot.
      // Treat as live; http_status is recorded so this is always auditable.
      verification = 'verified';  blocked++;
    } else {
      verification = 'stale';     inconclusive++;
    }

    await sbPatch(env, 'resource', `id=eq.${r.id}`, {
      http_status: status,
      last_verified: new Date().toISOString(),
      check_attempts: (r.check_attempts || 0) + 1,
      verification,
      updated_at: new Date().toISOString()
    });
  }

  const remaining = await sbCount(
    env, 'resource', 'verification=in.(unverified,stale)&check_attempts=lt.3'
  );

  return { checked: rows.length, alive, blocked, gone, inconclusive, remaining };
}

// Re-queue advice links that have not been checked recently, so a resource that
// dies is withdrawn from the takeaway rather than served to someone who then
// rings a dead number.
async function requeueStaleResources(env) {
  const cutoff = new Date(Date.now() - RESOURCE_TTL_MS).toISOString();
  await sbPatch(
    env,
    'resource',
    `verification=eq.verified&last_verified=lt.${cutoff}`,
    { verification: 'unverified', check_attempts: 0 }
  );
}

// ---- Step 5: geocode any org with a postcode but no coordinates ----
// Serves both the charity spine and the CQC district gap. postcodes.io is free,
// no key, 100 per bulk POST.
async function processGeocode(env, n) {
  const rows = await sbGet(
    env,
    `org?lat=is.null&postcode=not.is.null&select=id,postcode&limit=${n}`
  );
  if (!rows.length) return { geocoded: 0, missed: 0, remaining: 0 };

  const postcodes = rows.map(r => r.postcode);
  const res = await fetch('https://api.postcodes.io/postcodes', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ postcodes })
  });
  const data = await res.json();

  const byPc = {};
  for (const item of (data.result || [])) {
    if (item.result && item.result.latitude != null) {
      byPc[item.query.toUpperCase()] = {
        lat: item.result.latitude,
        lng: item.result.longitude,
        district: item.result.admin_district || null
      };
    }
  }

  let geocoded = 0, missed = 0;
  for (const r of rows) {
    const hit = byPc[(r.postcode || '').toUpperCase()];
    if (hit) {
      await sbPatch(env, 'org', `id=eq.${r.id}`, {
        lat: hit.lat, lng: hit.lng, district: hit.district,
        updated_at: new Date().toISOString()
      });
      geocoded++;
    } else {
      // Sentinel so an unresolvable postcode is not retried for ever.
      // -999 is outside any real coordinate and easy to find later.
      await sbPatch(env, 'org', `id=eq.${r.id}`, { lat: -999, lng: -999 });
      missed++;
    }
  }

  const remaining = await sbCount(env, 'org', 'lat=is.null&postcode=not.is.null');
  return { geocoded, missed, remaining };
}

// ---- Step 6: relevance-and-domain tag charities from activity text ----
// Unlike the CQC categories, every charity has distinct free-text, so this is a
// genuine judgement per row: is this something an isolated older person could
// act on, and if so which ASCOT domains. Grant-only trusts and irrelevant
// charities are marked takeaway_eligible=false with no domains, but kept.
async function processCharityTags(env, n) {
  const orgs = await sbGet(
    env,
    `org?sector=eq.voluntary&relevance_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}` +
    `&select=id,name,description,tag_attempts&order=income.desc.nullslast&limit=${n}`
  );

  let eligible = 0, excluded = 0, failed = 0;

  for (const o of orgs) {
    try {
      const verdict = await tagCharity(env, o);

      if (verdict.eligible && verdict.domains.length) {
        const rows = verdict.domains.map(d => ({
          org_id: o.id, domain: d.domain, confidence: d.confidence,
          method: 'ai', model: AI_MODEL
        }));
        await sbPost(env, 'org_domain?on_conflict=org_id,domain', rows, 'resolution=merge-duplicates');
      }

      await sbPatch(env, 'org', `id=eq.${o.id}`, {
        takeaway_eligible: verdict.eligible,
        self_referable: verdict.self_referable,
        relevance_checked: true,
        tagged: true,
        updated_at: new Date().toISOString()
      });

      if (verdict.eligible) eligible++; else excluded++;
    } catch (e) {
      await sbPatch(env, 'org', `id=eq.${o.id}`, {
        tag_attempts: (o.tag_attempts || 0) + 1
      });
      failed++;
    }
  }

  const remaining = await sbCount(
    env, 'org',
    `sector=eq.voluntary&relevance_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`
  );
  return { eligible, excluded, failed, remaining };
}

async function tagCharity(env, o) {
  const system =
    'You are triaging UK charities for a service that signposts older adults ' +
    '(65+) living at home, who are below the social-care eligibility threshold, ' +
    'to local support they can act on themselves.\n\n' +
    'Given a charity name and its registered activities, decide:\n' +
    '1. eligible: true only if an isolated or declining older person could ' +
    'plausibly contact or attend this DIRECTLY for support, company, activity, ' +
    'advice or practical help. Set false for: grant-giving trusts and ' +
    'endowments, almshouses and other allocated housing (cannot self-refer), ' +
    'charities serving only children or other unrelated groups, animal ' +
    'charities, research funds, museums, and anything a member of the public ' +
    'cannot simply approach.\n' +
    'IMPORTANT nuances:\n' +
    '  - A faith-based sponsor does NOT make a charity ineligible. Judge the ' +
    'SERVICE, not the sponsor. "Christian charity providing care and support to ' +
    'the elderly" is ELIGIBLE. Only exclude for religion when the activity is ' +
    'purely worship or propagation of faith with no practical service.\n' +
    '  - Substance misuse, drug and alcohol, and addiction services are NOT ' +
    'eligible for this tool, even though they help people. They are ' +
    'inappropriate to surface to an older adult completing a wellbeing screen. ' +
    'Set eligible false for these.\n' +
    '2. self_referable: can a person contact them directly without a ' +
    'professional referral.\n' +
    '3. domains: if eligible, the ASCOT domains it plausibly helps with, from: ' +
    'control, personal_care, food, safety, social, occupation, accommodation, ' +
    'dignity. Each {"domain":"<key>","confidence":0-1}. If not eligible, [].\n\n' +
    'Return ONLY JSON: {"eligible":bool,"self_referable":bool,"domains":[...]}. ' +
    'Be strict on eligibility. A village hall that hosts groups is eligible ' +
    '(social, occupation). A relief-in-need charity that only gives grants is not.';

  const user = `Name: ${o.name}\nActivities: ${o.description || 'none stated'}`;

  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ANTHROPIC_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: AI_MODEL, max_tokens: 400, system,
      messages: [{ role: 'user', content: user }]
    })
  });

  const data = await r.json();
  if (data.error) throw new Error(data.error.message);

  const text = (data.content || []).map(c => c.text || '').join('');
  const clean = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  let v;
  try { v = JSON.parse(clean); } catch (e) { throw new Error('unparseable: ' + clean.slice(0, 120)); }

  const domains = Array.isArray(v.domains)
    ? v.domains.filter(x => DOMAINS.includes(x.domain))
    : [];

  return {
    eligible: v.eligible === true,
    self_referable: v.self_referable === true,
    domains
  };
}

// ---- Step 7: audience refinement ----
// Keyword rules over-include: village halls (venues), churches (worship), and
// right-service-wrong-audience charities (youth, domestic abuse, LGBT support).
// This pass asks the one question rules cannot: would an isolated older person
// actually use this. It sets older_people_relevant and corrects provision_type,
// over the eligible voluntary set only. It does NOT re-run the whole tagger.
async function processRefine(env, n) {
  const orgs = await sbGet(
    env,
    `org?sector=eq.voluntary&takeaway_eligible=is.true&audience_checked=eq.false` +
    `&tag_attempts=lt.${MAX_TAG_ATTEMPTS}` +
    `&select=id,name,description,provision_type,tag_attempts&order=name&limit=${n}`
  );

  let relevant = 0, dropped = 0, failed = 0;

  for (const o of orgs) {
    try {
      const v = await refineOrg(env, o);

      const patch = {
        older_people_relevant: v.older_people_relevant,
        audience_checked: true,
        provision_type: v.provision_type,
        refine_notes: v.reason ? v.reason.slice(0, 300) : null,
        updated_at: new Date().toISOString()
      };
      // A charity that is not for this cohort stays in the DB but leaves the
      // takeaway. This is what keeps the scorecard honest.
      if (!v.older_people_relevant) patch.takeaway_eligible = false;

      await sbPatch(env, 'org', `id=eq.${o.id}`, patch);

      if (v.older_people_relevant) relevant++; else dropped++;
    } catch (e) {
      await sbPatch(env, 'org', `id=eq.${o.id}`, {
        tag_attempts: (o.tag_attempts || 0) + 1
      });
      failed++;
    }
  }

  const remaining = await sbCount(
    env, 'org',
    `sector=eq.voluntary&takeaway_eligible=is.true&audience_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`
  );
  return { relevant, dropped, failed, remaining };
}

async function refineOrg(env, o) {
  const system =
    'You are refining a directory of support for ISOLATED OLDER ADULTS (65+) ' +
    'living at home, below the social-care threshold, who scored poorly on a ' +
    'wellbeing screen (loneliness, low activity, declining independence).\n\n' +
    'For the given charity, decide THREE things:\n\n' +
    '1. older_people_relevant (bool): would an isolated older person plausibly ' +
    'use this, directly, for company, activity, practical help or advice they ' +
    'can act on. Set FALSE for, even though these are worthy: places of worship ' +
    'whose activity is essentially religious services (a church running a named ' +
    'lunch club or befriending scheme IS relevant; a church "providing sacred ' +
    'space for worship" is NOT); services aimed at other groups (children and ' +
    'youth, domestic abuse, LGBT identity support, addiction, asylum, students); ' +
    'grant-givers; anything a person cannot simply approach.\n\n' +
    '2. provision_type (string): "service" if it runs its own activity a person ' +
    'attends (lunch club, day centre, befriending, meals, support group, advice ' +
    'service). "venue" if it is essentially a room for hire (village/community/ ' +
    'church hall, community centre, pavilion) with no named older-people ' +
    'programme of its own. "unknown" if genuinely unclear.\n\n' +
    '3. reason (short string): one clause saying why, e.g. "worship only", ' +
    '"youth service", "genuine day centre for elderly", "hall for hire".\n\n' +
    'Return ONLY JSON: {"older_people_relevant":bool,"provision_type":"service|venue|unknown","reason":"..."}.';

  const user = `Name: ${o.name}\nActivities: ${o.description || 'none stated'}`;

  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ANTHROPIC_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: AI_MODEL, max_tokens: 300, system,
      messages: [{ role: 'user', content: user }]
    })
  });

  const data = await r.json();
  if (data.error) throw new Error(data.error.message);

  const text = (data.content || []).map(c => c.text || '').join('');
  const clean = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  let v;
  try { v = JSON.parse(clean); } catch (e) { throw new Error('unparseable: ' + clean.slice(0, 120)); }

  const pt = ['service', 'venue', 'unknown'].includes(v.provision_type) ? v.provision_type : 'unknown';
  return {
    older_people_relevant: v.older_people_relevant === true,
    provision_type: pt,
    reason: typeof v.reason === 'string' ? v.reason : null
  };
}

// ---- Router ----
function json(obj, status = 200) {
  return new Response(JSON.stringify(obj, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json' }
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname !== '/ingest') {
      return new Response(
        'Kent+Medway ingest worker. Use /ingest?step=seed|locations|tag|links|geocode|ctag|refine',
        { status: 200 }
      );
    }

    const step = url.searchParams.get('step') || 'status';
    const n = parseInt(url.searchParams.get('n') || '', 10);

    try {
      if (step === 'seed')      return json({ seeded: await seed(env) });
      if (step === 'locations') return json(await processLocations(env, n || LOC_BATCH));
      if (step === 'tag')       return json(await processTags(env, n || TAG_BATCH));
      if (step === 'links')     return json(await processLinks(env, n || LINK_BATCH));
      if (step === 'geocode')   return json(await processGeocode(env, n || 100));
      if (step === 'ctag')      return json(await processCharityTags(env, n || 10));
      if (step === 'refine')    return json(await processRefine(env, n || 10));

      const st = await sbGet(env, 'ingest_state?id=eq.cqc&select=seen,upserted,pending,last_seed');
      const untagged  = await sbCount(env, 'org', `tagged=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`);
      const stuck     = await sbCount(env, 'org', `tagged=eq.false&tag_attempts=gte.${MAX_TAG_ATTEMPTS}`);
      const unchecked = await sbCount(env, 'resource', 'verification=in.(unverified,stale)&check_attempts=lt.3');
      const resGone   = await sbCount(env, 'resource', 'verification=eq.removed');
      const resStuck  = await sbCount(env, 'resource', 'verification=eq.stale&check_attempts=gte.3');
      const ungeocoded = await sbCount(env, 'org', 'lat=is.null&postcode=not.is.null');
      const cUnchecked = await sbCount(env, 'org', `sector=eq.voluntary&relevance_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`);
      const cEligible  = await sbCount(env, 'org', 'sector=eq.voluntary&takeaway_eligible=is.true');

      return json({
        locations: st[0]
          ? {
              seen: st[0].seen,
              upserted: st[0].upserted,
              remaining: (st[0].pending || []).length,
              last_seed: st[0].last_seed
            }
          : null,
        tagging:   { untagged, retired_after_failures: stuck },
        resources: { unchecked, confirmed_gone: resGone, unreachable: resStuck },
        geocoding: { ungeocoded },
        charities: { untagged: cUnchecked, takeaway_eligible: cEligible },
        refinement: {
          unrefined: await sbCount(env, 'org', `sector=eq.voluntary&takeaway_eligible=is.true&audience_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`),
          services: await sbCount(env, 'org', "sector=eq.voluntary&takeaway_eligible=is.true&provision_type=eq.service&audience_checked=eq.true"),
          venues: await sbCount(env, 'org', "sector=eq.voluntary&takeaway_eligible=is.true&provision_type=eq.venue&audience_checked=eq.true")
        }
      });
    } catch (e) {
      return json({ error: String(e.message || e) }, 500);
    }
  },

  // One job per tick, so a single invocation stays well inside the free-plan
  // subrequest ceiling of 50.
  async scheduled(event, env, ctx) {
    ctx.waitUntil((async () => {
      const st      = await sbGet(env, 'ingest_state?id=eq.cqc&select=pending,last_seed');
      const pending = st.length ? (st[0].pending || []).length : 0;
      const stale   = !st.length || !st[0].last_seed ||
                      (Date.now() - Date.parse(st[0].last_seed) > 7 * 24 * 3600 * 1000);

      if (!st.length || (stale && pending === 0)) { await seed(env); return; }
      if (pending > 0) { await processLocations(env, LOC_BATCH); return; }

      const untagged = await sbCount(env, 'org', `tagged=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`);
      if (untagged > 0) { await processTags(env, TAG_BATCH); return; }

      const ungeocoded = await sbCount(env, 'org', 'lat=is.null&postcode=not.is.null');
      if (ungeocoded > 0) { await processGeocode(env, 100); return; }

      const cUntagged = await sbCount(env, 'org', `sector=eq.voluntary&relevance_checked=eq.false&tag_attempts=lt.${MAX_TAG_ATTEMPTS}`);
      if (cUntagged > 0) { await processCharityTags(env, TAG_BATCH); return; }

      await requeueStaleResources(env);
      await processLinks(env, LINK_BATCH);
    })());
  }
};

/*
  ---------------------------------------------------------------------------
  TWO KNOWN-WRONG FIELDS, LEFT ALONE ON PURPOSE
  ---------------------------------------------------------------------------
  sector: 'statutory' is stamped on every CQC row. But CQC registers private
  provision too, and 768 of your rows are dentists and 61 are clinics, most of
  them commercial. Every row in the database currently claims to be statutory,
  which makes the enum meaningless and will mislead the takeaway.

  districts: [loc.localAuthority] yields 'Kent' or 'Medway' on every row, never
  Canterbury, Thanet, Swale or Dover. The GIN index on districts is therefore
  dead weight, and any district filter will match everything or nothing.

  Both are one-line fixes here, but both rewrite ~4,300 rows you already have.
  Say the word and I will send the corrected version plus a backfill migration
  that derives district from postcode, which you have on 100% of rows, so no
  re-ingest from CQC is needed.
  ---------------------------------------------------------------------------
*/
