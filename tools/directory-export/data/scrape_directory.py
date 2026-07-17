#!/usr/bin/env python3
"""
Involve Kent directory scraper (v2, self-diagnosing).

Retrieves every listing from the Involve Kent online directory and builds a
normalised database (SQLite) plus CSV and JSON exports. Run with the owner's
permission only.

It tries several routes and reports exactly what it finds at each step, so if
it comes back empty you can read (or send me) data/diagnostics.txt and we can
pin the cause immediately.

Routes, in order:
  1. WordPress REST API. Confirms /wp-json is reachable, lists the site's post
     types, finds the directory type (or tries sensible endpoint guesses), then
     paginates 100 records at a time with ACF fields and embedded categories.
  2. XML sitemap crawl. Tries the WordPress core sitemap AND common plugin
     locations (Yoast, Rank Math), finds the directory sub-sitemap, collects
     every listing URL and parses each page.

Usage:
    python scrape_directory.py
    python scrape_directory.py --rest-base directory_entry
    python scrape_directory.py --sitemap-url https://involvekent.org.uk/sitemap_index.xml
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
USER_AGENT = (
    "InvolveKentDirectoryExport/2.0 (data export run with owner permission; "
    "contact: directory@involvekent.org.uk)"
)
REQUEST_DELAY = 0.4
PER_PAGE = 100
MAX_RETRIES = 4

# Endpoint slugs to try if schema discovery does not name the directory type.
REST_BASE_GUESSES = [
    "directory_entry", "directory-entry", "directory_entries",
    "directory-entries", "directory", "listings", "listing",
]

# Sitemap locations to try, in order.
SITEMAP_GUESSES = [
    "/wp-sitemap.xml", "/sitemap_index.xml", "/sitemap.xml",
    "/sitemap-index.xml", "/directory-sitemap.xml",
]

DIAG: list[str] = []


def log(msg: str) -> None:
    print(msg, flush=True)
    DIAG.append(msg)


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

def make_session() -> requests.Session:
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
                wait = min(2 ** attempt, 30)
                time.sleep(wait)
                continue
            return resp  # return non-200 so caller can log the code
        except requests.RequestException as exc:
            wait = min(2 ** attempt, 30)
            log(f"  request error on {url}: {exc} (retry in {wait}s)")
            time.sleep(wait)
    return None


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

def strip_html(value) -> str:
    if value is None:
        return ""
    if isinstance(value, dict):
        value = value.get("rendered", "")
    text = re.sub(r"<[^>]+>", " ", str(value))
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def flatten(prefix, obj, out) -> None:
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


# ---------------------------------------------------------------------------
# REST route
# ---------------------------------------------------------------------------

def rest_alive(session, base_url) -> bool:
    resp = get(session, urljoin(base_url, "/wp-json/"))
    if resp is None:
        log("  /wp-json/ : no response")
        return False
    log(f"  /wp-json/ : HTTP {resp.status_code}")
    return resp.status_code == 200


def discover_rest_base(session, base_url):
    resp = get(session, urljoin(base_url, "/wp-json/wp/v2/types"))
    if resp is None or resp.status_code != 200:
        log(f"  /wp-json/wp/v2/types : HTTP {getattr(resp, 'status_code', 'none')}")
        return None
    try:
        types = resp.json()
    except ValueError:
        log("  /wp-json/wp/v2/types : did not return JSON")
        return None
    log(f"  post types found: {', '.join(sorted(types.keys()))}")
    candidates = []
    for slug, info in types.items():
        rest_base = info.get("rest_base") or slug
        if "directory" in f"{slug} {rest_base}".lower():
            candidates.append((slug, rest_base))
    for slug, rest_base in candidates:
        if slug == "directory_entry":
            log(f"  selected directory type: {slug} (rest_base={rest_base})")
            return rest_base
    if candidates:
        log(f"  selected directory type: {candidates[0][0]} (rest_base={candidates[0][1]})")
        return candidates[0][1]
    log("  no post type name contained 'directory'")
    return None


def fetch_all_entries(session, base_url, rest_base):
    endpoint = urljoin(base_url, f"/wp-json/wp/v2/{rest_base}")
    probe = get(session, endpoint, params={"per_page": 1, "_embed": 1})
    if probe is None:
        log(f"  {endpoint} : no response")
        return []
    if probe.status_code != 200:
        log(f"  {endpoint} : HTTP {probe.status_code} (endpoint not usable)")
        return []
    total = probe.headers.get("X-WP-Total", "?")
    total_pages = int(probe.headers.get("X-WP-TotalPages", "0") or 0)
    log(f"  {endpoint} : OK, reports {total} entries / {total_pages or '?'} pages")

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
        if total_pages and page >= total_pages:
            break
        if len(batch) < PER_PAGE:
            break
        page += 1
    return entries


def normalise_entry(raw):
    record = {
        "id": raw.get("id"),
        "title": strip_html(raw.get("title")),
        "slug": raw.get("slug", ""),
        "url": raw.get("link", ""),
        "date": raw.get("date", ""),
        "modified": raw.get("modified", ""),
        "description": strip_html(raw.get("content")),
        "excerpt": strip_html(raw.get("excerpt")),
    }
    acf = raw.get("acf")
    if isinstance(acf, dict):
        flat = {}
        flatten("", acf, flat)
        for k, v in flat.items():
            record[f"acf.{k}"] = v

    def first_match(*needles):
        for key, value in record.items():
            if key.startswith("acf.") and any(n in key.lower() for n in needles):
                if value not in (None, "", []):
                    return value
        return ""

    record["email"] = first_match("email")
    record["phone"] = first_match("phone", "telephone", "contact_number", "tel")
    record["website"] = first_match("website", "url", "web")
    record["address"] = first_match("address", "location")
    record["postcode"] = first_match("postcode", "post_code")

    cats = []
    for group in (raw.get("_embedded", {}) or {}).get("wp:term", []) or []:
        for term in group:
            if term.get("name"):
                cats.append(strip_html(term["name"]))
    record["categories"] = "; ".join(sorted(set(cats)))
    record["_raw"] = raw
    return record


# ---------------------------------------------------------------------------
# Sitemap route
# ---------------------------------------------------------------------------

def find_sitemap(session, base_url, override):
    locations = [override] if override else SITEMAP_GUESSES
    for loc in locations:
        url = loc if loc.startswith("http") else urljoin(base_url, loc)
        resp = get(session, url)
        code = getattr(resp, "status_code", "none")
        log(f"  sitemap {url} : HTTP {code}")
        if resp is not None and resp.status_code == 200 and "<" in resp.text:
            return url, resp.text
    return None, None


def collect_sitemap_urls(session, base_url, override):
    root_url, xml = find_sitemap(session, base_url, override)
    if not xml:
        return []
    locs = re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", xml)

    # Is this an index of sub-sitemaps, or a flat list of page URLs?
    is_index = "<sitemapindex" in xml.lower()
    entry_urls = []

    def wanted_submap(name):
        low = name.lower()
        has_dir = "directory" in low
        excluded = any(x in low for x in ("categor", "taxonom", "author", "user", "tag"))
        return has_dir and not excluded

    if is_index:
        picked = [u for u in locs if wanted_submap(u)]
        if not picked:
            log("  no directory sub-sitemap by name; scanning all sub-sitemaps")
            picked = locs
        for sm in picked:
            page = get(session, sm)
            if page is None or page.status_code != 200:
                continue
            urls = re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", page.text)
            if wanted_submap(sm):
                entry_urls.extend(urls)
            else:
                entry_urls.extend(u for u in urls if "directory" in u.lower())
    else:
        entry_urls = [u for u in locs if "directory" in u.lower()]

    entry_urls = sorted(set(entry_urls))
    log(f"  collected {len(entry_urls)} candidate listing URLs from sitemap")
    return entry_urls


def parse_entry_page(session, url):
    record = {"url": url, "title": "", "email": "", "phone": "", "website": "",
              "address": "", "postcode": "", "description": "", "excerpt": "",
              "categories": "", "date": "", "modified": "", "slug": "", "id": None, "_raw": {}}
    resp = get(session, url)
    if resp is None or resp.status_code != 200 or not HAVE_BS4:
        return record
    soup = BeautifulSoup(resp.text, "html.parser")
    h1 = soup.find("h1")
    if h1:
        record["title"] = h1.get_text(strip=True)
    elif soup.title:
        record["title"] = soup.title.get_text().split(" - ")[0].strip()

    for a in soup.select('a[href^="mailto:"]'):
        record["email"] = a["href"].replace("mailto:", "").split("?")[0].strip()
        break
    for a in soup.select('a[href^="tel:"]'):
        record["phone"] = a["href"].replace("tel:", "").strip()
        break
    own = urlparse(url).netloc.lower()
    for a in soup.select("a[href]"):
        host = urlparse(a["href"]).netloc.lower()
        if host and own not in host and not any(
            s in host for s in ("facebook", "twitter", "instagram", "linkedin", "youtube", "google", "involvekent")
        ):
            record["website"] = a["href"]
            break

    for tag in soup.find_all("script", type="application/ld+json"):
        try:
            data = json.loads(tag.string or "{}")
        except (ValueError, TypeError):
            continue
        for b in (data if isinstance(data, list) else [data]):
            if not isinstance(b, dict):
                continue
            addr = b.get("address")
            if isinstance(addr, dict):
                parts = [addr.get(k, "") for k in
                         ("streetAddress", "addressLocality", "addressRegion", "postalCode")]
                record["address"] = ", ".join(p for p in parts if p) or record["address"]
                record["postcode"] = addr.get("postalCode", "") or record["postcode"]
            elif isinstance(addr, str):
                record["address"] = addr or record["address"]
            record["phone"] = record["phone"] or b.get("telephone", "")
    return record


# ---------------------------------------------------------------------------
# Database + exports
# ---------------------------------------------------------------------------

def build_database(records, outdir):
    db_path = f"{outdir}/directory.db"
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript("""
        DROP TABLE IF EXISTS entry_categories;
        DROP TABLE IF EXISTS categories;
        DROP TABLE IF EXISTS entries;
        CREATE TABLE entries (
            id INTEGER PRIMARY KEY, title TEXT, slug TEXT, url TEXT, date TEXT,
            modified TEXT, email TEXT, phone TEXT, website TEXT, address TEXT,
            postcode TEXT, description TEXT, excerpt TEXT, categories TEXT, raw_json TEXT
        );
        CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE);
        CREATE TABLE entry_categories (
            entry_id INTEGER, category_id INTEGER, PRIMARY KEY (entry_id, category_id)
        );
    """)
    cat_ids = {}
    for i, r in enumerate(records):
        entry_id = r.get("id") or (10_000_000 + i)
        cur.execute("""INSERT OR REPLACE INTO entries
            (id,title,slug,url,date,modified,email,phone,website,address,postcode,
             description,excerpt,categories,raw_json) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (entry_id, r.get("title", ""), r.get("slug", ""), r.get("url", ""),
             r.get("date", ""), r.get("modified", ""), r.get("email", ""), r.get("phone", ""),
             r.get("website", ""), r.get("address", ""), r.get("postcode", ""),
             r.get("description", ""), r.get("excerpt", ""), r.get("categories", ""),
             json.dumps(r.get("_raw", {}), ensure_ascii=False)))
        for cat in [c.strip() for c in r.get("categories", "").split(";") if c.strip()]:
            if cat not in cat_ids:
                cur.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (cat,))
                cur.execute("SELECT id FROM categories WHERE name = ?", (cat,))
                cat_ids[cat] = cur.fetchone()[0]
            cur.execute("INSERT OR IGNORE INTO entry_categories VALUES (?,?)",
                        (entry_id, cat_ids[cat]))
    conn.commit()
    conn.close()
    return db_path


def export_csv_json(records, outdir):
    columns = ["id", "title", "url", "email", "phone", "website", "address",
               "postcode", "categories", "description", "excerpt", "date", "modified"]
    csv_path = f"{outdir}/directory.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=columns, extrasaction="ignore")
        w.writeheader()
        for r in records:
            w.writerow({c: r.get(c, "") for c in columns})
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

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    ap.add_argument("--outdir", default="data")
    ap.add_argument("--rest-base", default=None, help="Force a REST endpoint slug.")
    ap.add_argument("--sitemap-url", default=None, help="Force a sitemap URL.")
    ap.add_argument("--no-html-fallback", action="store_true")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    session = make_session()
    log(f"Run started {datetime.now(timezone.utc):%Y-%m-%d %H:%M UTC} against {args.base_url}")
    records = []

    # --- REST route ---
    log("Route 1: WordPress REST API")
    if rest_alive(session, args.base_url):
        rest_base = args.rest_base or discover_rest_base(session, args.base_url)
        tried = [rest_base] if rest_base else []
        tried += [g for g in REST_BASE_GUESSES if g not in tried]
        for base in tried:
            if not base:
                continue
            log(f"  trying endpoint '{base}'")
            raw = fetch_all_entries(session, args.base_url, base)
            if raw:
                records = [normalise_entry(r) for r in raw]
                break
    else:
        log("  REST API not reachable; skipping to sitemap")

    # Fill contact gaps from live pages where ACF was not exposed.
    if records and not args.no_html_fallback and HAVE_BS4:
        missing = [r for r in records if not (r["email"] or r["phone"] or r["website"])]
        if missing:
            log(f"Filling contact gaps for {len(missing)} entries via page parse")
            for r in missing:
                if r.get("url"):
                    p = parse_entry_page(session, r["url"])
                    for f in ("email", "phone", "website", "address", "postcode"):
                        r[f] = r[f] or p.get(f, "")

    # --- Sitemap route (if REST produced nothing) ---
    if not records:
        log("Route 2: XML sitemap crawl")
        urls = collect_sitemap_urls(session, args.base_url, args.sitemap_url)
        for i, url in enumerate(urls, 1):
            if i % 25 == 0:
                log(f"  parsed {i}/{len(urls)}")
            records.append(parse_entry_page(session, url))

    # --- Outputs ---
    if not records:
        log("RESULT: no records retrieved by any route.")
        log("Send me data/diagnostics.txt and I will pin the exact cause.")
        write_diagnostics(args.outdir)
        return 1

    db_path = build_database(records, args.outdir)
    csv_path, json_path = export_csv_json(records, args.outdir)
    log("=" * 56)
    log(f"RESULT: {len(records)} entries")
    log(f"  with email   : {sum(1 for r in records if r.get('email'))}")
    log(f"  with phone   : {sum(1 for r in records if r.get('phone'))}")
    log(f"  with website : {sum(1 for r in records if r.get('website'))}")
    log(f"  SQLite : {db_path}")
    log(f"  CSV    : {csv_path}")
    log(f"  JSON   : {json_path}")
    log("=" * 56)
    write_diagnostics(args.outdir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
