#!/usr/bin/env python3
"""
Involve Kent directory scraper (v3, self-diagnosing).

Retrieves every listing from the Involve Kent online directory
(https://involvekent.org.uk/directory/) and builds a normalised database
(SQLite) plus CSV and JSON exports. Run with the owner's permission only.

Confirmed facts this version is built around:
  - Listings live at /directory/{slug}/ and are fully server-rendered.
  - Each page has labelled sections: Address, What we do, Price, Organisation,
    Telephone, Email. The site's own contact details sit in the header/footer
    of every page and are deliberately excluded.
  - The site runs Yoast SEO, so its sitemap index is at /sitemap_index.xml.

Routes, in order:
  1. WordPress REST API (best case: also yields category tags).
  2. XML sitemap crawl -> parse each /directory/{slug}/ page.
  3. A supplied list of URLs (--urls-file), if discovery is bypassed.

Whatever happens, it writes data/diagnostics.txt describing every step.
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import os
import re
import sqlite3
import sys
import time
from datetime import datetime, timezone
from urllib.parse import urljoin, urlparse

import requests

try:
    from bs4 import BeautifulSoup
    HAVE_BS4 = True
except Exception:
    HAVE_BS4 = False


DEFAULT_BASE = "https://involvekent.org.uk"
USER_AGENT = ("InvolveKentDirectoryExport/3.0 (data export run with owner "
             "permission; contact: directory@involvekent.org.uk)")
REQUEST_DELAY = 0.4
PER_PAGE = 100
MAX_RETRIES = 4

REST_BASE_GUESSES = ["directory_entry", "directory-entry", "directory_entries",
                     "directory-entries", "directory", "listings", "listing"]
SITEMAP_GUESSES = ["/sitemap_index.xml", "/wp-sitemap.xml", "/sitemap.xml",
                   "/directory_entry-sitemap.xml", "/directory-sitemap.xml",
                   "/wp-sitemap-posts-directory_entry-1.xml"]

OWN_EMAILS = {"hello@involvekent.org.uk"}
OWN_PHONES = {"03000810005"}
KNOWN_LABELS = {"address", "what we do", "price", "organisation", "telephone", "email"}

DIAG: list[str] = []


def log(msg: str) -> None:
    print(msg, flush=True)
    DIAG.append(msg)


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

def make_session():
    s = requests.Session()
    s.headers.update({"User-Agent": USER_AGENT, "Accept": "application/json, text/xml, */*"})
    return s


def get(session, url, params=None):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = session.get(url, params=params, timeout=30)
            if resp.status_code == 200:
                time.sleep(REQUEST_DELAY)
                return resp
            if resp.status_code in (429, 500, 502, 503, 504):
                time.sleep(min(2 ** attempt, 30))
                continue
            return resp
        except requests.RequestException as exc:
            log(f"  request error on {url}: {exc}")
            time.sleep(min(2 ** attempt, 30))
    return None


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

def strip_html(value):
    if value is None:
        return ""
    if isinstance(value, dict):
        value = value.get("rendered", "")
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", str(value)))).strip()


def flatten(prefix, obj, out):
    if isinstance(obj, dict):
        for k, v in obj.items():
            flatten(f"{prefix}.{k}" if prefix else str(k), v, out)
    elif isinstance(obj, list):
        simple = [x for x in obj if not isinstance(x, (dict, list))]
        if len(simple) == len(obj):
            out[prefix] = "; ".join(str(x) for x in obj)
        else:
            for i, v in enumerate(obj):
                flatten(f"{prefix}[{i}]", v, out)
    else:
        out[prefix] = obj


def digits(s):
    return re.sub(r"\D", "", s or "")


# ---------------------------------------------------------------------------
# REST route
# ---------------------------------------------------------------------------

def rest_alive(session, base_url):
    resp = get(session, urljoin(base_url, "/wp-json/"))
    code = getattr(resp, "status_code", "none")
    log(f"  /wp-json/ : HTTP {code}")
    return resp is not None and resp.status_code == 200


def discover_rest_base(session, base_url):
    resp = get(session, urljoin(base_url, "/wp-json/wp/v2/types"))
    if resp is None or resp.status_code != 200:
        log(f"  /wp-json/wp/v2/types : HTTP {getattr(resp, 'status_code', 'none')}")
        return None
    try:
        types = resp.json()
    except ValueError:
        log("  /wp-json/wp/v2/types : not JSON")
        return None
    log(f"  post types: {', '.join(sorted(types.keys()))}")
    cands = []
    for slug, info in types.items():
        rb = info.get("rest_base") or slug
        if "directory" in f"{slug} {rb}".lower():
            cands.append((slug, rb))
    for slug, rb in cands:
        if slug == "directory_entry":
            return rb
    return cands[0][1] if cands else None


def fetch_all_entries(session, base_url, rest_base):
    endpoint = urljoin(base_url, f"/wp-json/wp/v2/{rest_base}")
    probe = get(session, endpoint, params={"per_page": 1, "_embed": 1})
    if probe is None or probe.status_code != 200:
        log(f"  {endpoint} : HTTP {getattr(probe, 'status_code', 'none')} (unusable)")
        return []
    total = probe.headers.get("X-WP-Total", "?")
    pages = int(probe.headers.get("X-WP-TotalPages", "0") or 0)
    log(f"  {endpoint} : OK, {total} entries / {pages or '?'} pages")
    entries, page = [], 1
    while True:
        resp = get(session, endpoint, params={"per_page": PER_PAGE, "page": page, "_embed": 1})
        if resp is None or resp.status_code != 200:
            break
        try:
            batch = resp.json()
        except ValueError:
            break
        if not batch:
            break
        entries.extend(batch)
        log(f"  page {page}: +{len(batch)} (total {len(entries)})")
        if (pages and page >= pages) or len(batch) < PER_PAGE:
            break
        page += 1
    return entries


def normalise_rest(raw):
    rec = {"id": raw.get("id"), "title": strip_html(raw.get("title")),
           "slug": raw.get("slug", ""), "url": raw.get("link", ""),
           "date": raw.get("date", ""), "modified": raw.get("modified", ""),
           "description": strip_html(raw.get("content")),
           "excerpt": strip_html(raw.get("excerpt")),
           "email": "", "phone": "", "website": "", "address": "", "postcode": "",
           "price": "", "organisation": "", "organisation_url": "", "categories": "",
           "_raw": raw}
    acf = raw.get("acf")
    if isinstance(acf, dict):
        flat = {}
        flatten("", acf, flat)
        for k, v in flat.items():
            rec[f"acf.{k}"] = v

        def fm(*needles):
            for key, val in rec.items():
                if key.startswith("acf.") and any(n in key.lower() for n in needles) \
                        and val not in (None, "", []):
                    return val
            return ""
        rec["email"] = fm("email")
        rec["phone"] = fm("phone", "telephone", "tel")
        rec["website"] = fm("website", "web", "url")
        rec["address"] = fm("address", "location")
        rec["postcode"] = fm("postcode", "post_code")
        rec["price"] = fm("price", "cost")
    cats = []
    for group in (raw.get("_embedded", {}) or {}).get("wp:term", []) or []:
        for term in group:
            if term.get("name"):
                cats.append(strip_html(term["name"]))
    rec["categories"] = "; ".join(sorted(set(cats)))
    return rec


# ---------------------------------------------------------------------------
# Sitemap route
# ---------------------------------------------------------------------------

def find_sitemap(session, base_url, override):
    for loc in ([override] if override else SITEMAP_GUESSES):
        url = loc if loc.startswith("http") else urljoin(base_url, loc)
        resp = get(session, url)
        code = getattr(resp, "status_code", "none")
        log(f"  sitemap {url} : HTTP {code}")
        if resp is not None and resp.status_code == 200 and "<loc>" in resp.text:
            return url, resp.text
    return None, None


def collect_sitemap_urls(session, base_url, override):
    root_url, xml = find_sitemap(session, base_url, override)
    if not xml:
        log("  no usable sitemap found")
        return []
    locs = re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", xml)
    is_index = "<sitemapindex" in xml.lower()

    def wanted(name):
        low = name.lower()
        return "directory" in low and not any(
            x in low for x in ("categor", "taxonom", "author", "user", "tag", "organisation"))

    entry_urls = []
    if is_index:
        log(f"  sitemap index lists {len(locs)} sub-sitemaps:")
        for u in locs:
            log(f"    - {u}")
        picked = [u for u in locs if wanted(u)]
        if not picked:
            log("  no directory sub-sitemap by name; scanning every sub-sitemap for /directory/ URLs")
            picked = locs
        for sm in picked:
            page = get(session, sm)
            if page is None or page.status_code != 200:
                continue
            urls = re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", page.text)
            if wanted(sm):
                entry_urls.extend(urls)
            else:
                entry_urls.extend(u for u in urls if "/directory/" in u.lower())
    else:
        entry_urls = [u for u in locs if "/directory/" in u.lower()]

    entry_urls = sorted(u for u in set(entry_urls)
                        if "/directory/" in u and not u.rstrip("/").endswith("/directory"))
    log(f"  collected {len(entry_urls)} listing URLs")
    return entry_urls


# ---------------------------------------------------------------------------
# HTML page parser (section-aware)
# ---------------------------------------------------------------------------

def sections_map(soup):
    out = {}
    for h in soup.find_all(re.compile(r"^h[1-6]$")):
        label = h.get_text(" ", strip=True).lower()
        if label not in KNOWN_LABELS:
            continue
        texts, hrefs = [], []
        for el in h.find_all_next():
            if el.name and re.match(r"^h[1-6]$", el.name):
                break
            if el.name == "a" and el.get("href"):
                hrefs.append(el["href"])
            if el.name in ("p", "a", "span", "div") and el.get_text(strip=True):
                texts.append(el.get_text(" ", strip=True))
        out[label] = (" ".join(dict.fromkeys(texts)).strip(), hrefs)
    return out


def extract_from_html(html_text, url):
    rec = {"url": url, "title": "", "email": "", "phone": "", "website": "",
           "address": "", "postcode": "", "price": "", "organisation": "",
           "organisation_url": "", "description": "", "excerpt": "",
           "categories": "", "date": "", "modified": "",
           "slug": url.rstrip("/").split("/")[-1], "id": None, "_raw": {}}
    soup = BeautifulSoup(html_text, "html.parser")
    h1 = soup.find("h1")
    if h1:
        rec["title"] = h1.get_text(" ", strip=True)
    sec = sections_map(soup)

    if "address" in sec:
        rec["address"] = sec["address"][0]
        m = re.search(r"[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}", rec["address"])
        if m:
            rec["postcode"] = m.group(0)
    if "what we do" in sec:
        rec["description"] = sec["what we do"][0]
    if "price" in sec:
        rec["price"] = sec["price"][0]
    if "organisation" in sec:
        rec["organisation"] = sec["organisation"][0]
        for href in sec["organisation"][1]:
            if "directory_entry_organisation" in href:
                rec["organisation_url"] = href
                break

    tel = []
    if "telephone" in sec:
        tel += [h[4:].strip() for h in sec["telephone"][1] if h.startswith("tel:")]
        if sec["telephone"][0]:
            tel.append(sec["telephone"][0])
    tel += [a["href"][4:].strip() for a in soup.select('a[href^="tel:"]')]
    for t in tel:
        if digits(t) and digits(t) not in OWN_PHONES:
            rec["phone"] = t.strip()
            break

    em = []
    if "email" in sec:
        em += [h[7:].split("?")[0].strip() for h in sec["email"][1] if h.startswith("mailto:")]
    em += [a["href"][7:].split("?")[0].strip() for a in soup.select('a[href^="mailto:"]')]
    for e in em:
        low = e.lower()
        if low and low not in OWN_EMAILS and not low.endswith("@involvekent.org.uk"):
            rec["email"] = e
            break

    own = urlparse(url).netloc.lower()
    for a in soup.select("a[href]"):
        host = urlparse(a["href"]).netloc.lower()
        if host and own not in host and not any(
            s in host for s in ("facebook", "twitter", "instagram", "linkedin",
                                "youtube", "google", "involvekent")):
            rec["website"] = a["href"]
            break
    return rec


def parse_entry_page(session, url):
    resp = get(session, url)
    if resp is None or resp.status_code != 200 or not HAVE_BS4:
        return {"url": url, "title": "", "email": "", "phone": "", "website": "",
                "address": "", "postcode": "", "price": "", "organisation": "",
                "organisation_url": "", "description": "", "excerpt": "",
                "categories": "", "date": "", "modified": "",
                "slug": url.rstrip("/").split("/")[-1], "id": None, "_raw": {}}
    return extract_from_html(resp.text, url)


# ---------------------------------------------------------------------------
# Database + exports
# ---------------------------------------------------------------------------

COLUMNS = ["id", "title", "slug", "url", "organisation", "organisation_url",
           "email", "phone", "website", "address", "postcode", "price",
           "categories", "description", "excerpt", "date", "modified"]


def build_database(records, outdir):
    db = f"{outdir}/directory.db"
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.executescript("""
        DROP TABLE IF EXISTS entry_categories;
        DROP TABLE IF EXISTS categories;
        DROP TABLE IF EXISTS entries;
        CREATE TABLE entries (
            id INTEGER PRIMARY KEY, title TEXT, slug TEXT, url TEXT,
            organisation TEXT, organisation_url TEXT, email TEXT, phone TEXT,
            website TEXT, address TEXT, postcode TEXT, price TEXT,
            categories TEXT, description TEXT, excerpt TEXT, date TEXT,
            modified TEXT, raw_json TEXT);
        CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE);
        CREATE TABLE entry_categories (entry_id INTEGER, category_id INTEGER,
            PRIMARY KEY (entry_id, category_id));
    """)
    cat_ids = {}
    for i, r in enumerate(records):
        eid = r.get("id") or (10_000_000 + i)
        cur.execute("""INSERT OR REPLACE INTO entries
            (id,title,slug,url,organisation,organisation_url,email,phone,website,
             address,postcode,price,categories,description,excerpt,date,modified,raw_json)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (eid, r.get("title", ""), r.get("slug", ""), r.get("url", ""),
             r.get("organisation", ""), r.get("organisation_url", ""), r.get("email", ""),
             r.get("phone", ""), r.get("website", ""), r.get("address", ""),
             r.get("postcode", ""), r.get("price", ""), r.get("categories", ""),
             r.get("description", ""), r.get("excerpt", ""), r.get("date", ""),
             r.get("modified", ""), json.dumps(r.get("_raw", {}), ensure_ascii=False)))
        for cat in [c.strip() for c in r.get("categories", "").split(";") if c.strip()]:
            if cat not in cat_ids:
                cur.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (cat,))
                cur.execute("SELECT id FROM categories WHERE name = ?", (cat,))
                cat_ids[cat] = cur.fetchone()[0]
            cur.execute("INSERT OR IGNORE INTO entry_categories VALUES (?,?)", (eid, cat_ids[cat]))
    conn.commit()
    conn.close()
    return db


def export_csv_json(records, outdir):
    csv_path = f"{outdir}/directory.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS, extrasaction="ignore")
        w.writeheader()
        for r in records:
            w.writerow({c: r.get(c, "") for c in COLUMNS})
    json_path = f"{outdir}/directory.json"
    clean = [{k: v for k, v in r.items() if k != "_raw"} for r in records]
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump(clean, fh, ensure_ascii=False, indent=2)
    return csv_path, json_path


def write_diagnostics(outdir):
    with open(f"{outdir}/diagnostics.txt", "w", encoding="utf-8") as fh:
        fh.write("\n".join(DIAG) + "\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    ap.add_argument("--outdir", default="data")
    ap.add_argument("--rest-base", default=None)
    ap.add_argument("--sitemap-url", default=None)
    ap.add_argument("--urls-file", default=None, help="Newline-separated listing URLs to parse directly.")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    session = make_session()
    log(f"Run started {datetime.now(timezone.utc):%Y-%m-%d %H:%M UTC} against {args.base_url}")
    records = []

    # Route 3 short-circuit: explicit URL list.
    if args.urls_file:
        log(f"Route 3: parsing URLs from {args.urls_file}")
        with open(args.urls_file, encoding="utf-8") as fh:
            urls = [ln.strip() for ln in fh if ln.strip()]
        for i, u in enumerate(urls, 1):
            if i % 25 == 0:
                log(f"  parsed {i}/{len(urls)}")
            records.append(parse_entry_page(session, u))
    else:
        # Route 1: REST.
        log("Route 1: WordPress REST API")
        if rest_alive(session, args.base_url):
            base = args.rest_base or discover_rest_base(session, args.base_url)
            tried = ([base] if base else []) + [g for g in REST_BASE_GUESSES if g != base]
            for b in tried:
                if not b:
                    continue
                log(f"  trying endpoint '{b}'")
                raw = fetch_all_entries(session, args.base_url, b)
                if raw:
                    records = [normalise_rest(r) for r in raw]
                    break
        else:
            log("  REST not reachable")

        # Fill contact gaps from live pages.
        if records and HAVE_BS4:
            missing = [r for r in records if not (r["email"] or r["phone"])]
            if missing:
                log(f"Filling contact gaps for {len(missing)} entries via page parse")
                for r in missing:
                    if r.get("url"):
                        p = parse_entry_page(session, r["url"])
                        for f in ("email", "phone", "website", "address", "postcode",
                                  "price", "organisation", "organisation_url"):
                            r[f] = r.get(f) or p.get(f, "")

        # Route 2: sitemap.
        if not records:
            log("Route 2: XML sitemap crawl")
            urls = collect_sitemap_urls(session, args.base_url, args.sitemap_url)
            for i, u in enumerate(urls, 1):
                if i % 25 == 0:
                    log(f"  parsed {i}/{len(urls)}")
                records.append(parse_entry_page(session, u))

    if not records:
        log("RESULT: no records retrieved by any route.")
        log("Send me data/diagnostics.txt (it now lists the sitemap contents) and I'll pin it.")
        write_diagnostics(args.outdir)
        return 1

    db = build_database(records, args.outdir)
    csv_path, json_path = export_csv_json(records, args.outdir)
    log("=" * 56)
    log(f"RESULT: {len(records)} entries")
    log(f"  with email        : {sum(1 for r in records if r.get('email'))}")
    log(f"  with phone        : {sum(1 for r in records if r.get('phone'))}")
    log(f"  with organisation : {sum(1 for r in records if r.get('organisation'))}")
    log(f"  with categories   : {sum(1 for r in records if r.get('categories'))}")
    log(f"  SQLite: {db}")
    log(f"  CSV   : {csv_path}")
    log(f"  JSON  : {json_path}")
    log("=" * 56)
    write_diagnostics(args.outdir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
