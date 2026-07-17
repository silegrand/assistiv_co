#!/usr/bin/env python3
"""
Involve Kent directory scraper.

Retrieves every listing from the Involve Kent online directory and builds a
normalised database (SQLite) plus CSV and JSON exports.

Run with the owner's permission only. This script is polite: it identifies
itself, rate-limits its requests, and only reads publicly published listings.

Strategy, in order of preference:
  1. WordPress REST API. The script discovers the correct post type and
     rest_base from the site's own schema, then paginates 100 records at a
     time, pulling ACF fields and embedded taxonomy terms.
  2. XML sitemap crawl. If the REST API is disabled, it walks the WordPress
     core sitemap, collects every directory-entry URL, and parses each page
     (JSON-LD, mailto:/tel: links, labelled fields) as a fallback.

Usage:
    python scrape_directory.py
    python scrape_directory.py --base-url https://involvekent.org.uk --outdir data
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import sqlite3
import sys
import time
from datetime import datetime, timezone
from urllib.parse import urljoin, urlparse

import requests

try:
    from bs4 import BeautifulSoup  # only needed for the HTML fallback paths
    HAVE_BS4 = True
except Exception:
    HAVE_BS4 = False


DEFAULT_BASE = "https://involvekent.org.uk"
USER_AGENT = (
    "InvolveKentDirectoryExport/1.0 (data export run with owner permission; "
    "contact: directory@involvekent.org.uk)"
)
REQUEST_DELAY = 0.4          # seconds between requests, be polite
PER_PAGE = 100               # WordPress REST maximum
MAX_RETRIES = 4


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update({"User-Agent": USER_AGENT, "Accept": "application/json, */*"})
    return s


def get(session: requests.Session, url: str, params: dict | None = None):
    """GET with retries and exponential backoff. Returns the Response or None."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = session.get(url, params=params, timeout=30)
            if resp.status_code == 200:
                time.sleep(REQUEST_DELAY)
                return resp
            if resp.status_code in (429, 500, 502, 503, 504):
                wait = min(2 ** attempt, 30)
                print(f"  {resp.status_code} on {url} - retry in {wait}s", file=sys.stderr)
                time.sleep(wait)
                continue
            # 4xx other than 429: not worth retrying
            print(f"  {resp.status_code} on {url} - giving up", file=sys.stderr)
            return None
        except requests.RequestException as exc:
            wait = min(2 ** attempt, 30)
            print(f"  error on {url}: {exc} - retry in {wait}s", file=sys.stderr)
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
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def flatten(prefix: str, obj, out: dict) -> None:
    """Flatten nested ACF dicts/lists into dotted keys for CSV friendliness."""
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
# REST API path
# ---------------------------------------------------------------------------

def discover_rest_base(session: requests.Session, base_url: str) -> str | None:
    """Find the rest_base for the directory post type from the site schema."""
    resp = get(session, urljoin(base_url, "/wp-json/wp/v2/types"))
    if not resp:
        return None
    try:
        types = resp.json()
    except ValueError:
        return None

    # Prefer an explicit directory post type; otherwise anything mentioning it.
    candidates = []
    for slug, info in types.items():
        rest_base = info.get("rest_base") or slug
        haystack = f"{slug} {rest_base} {info.get('name','')}".lower()
        if "directory" in haystack:
            candidates.append((slug, rest_base))
    for slug, rest_base in candidates:
        if slug == "directory_entry":
            return rest_base
    if candidates:
        return candidates[0][1]
    return None


def fetch_all_entries(session: requests.Session, base_url: str, rest_base: str) -> list[dict]:
    """Paginate the REST endpoint and return raw entry dicts."""
    endpoint = urljoin(base_url, f"/wp-json/wp/v2/{rest_base}")
    entries: list[dict] = []
    page = 1
    total_pages = None
    while True:
        resp = get(session, endpoint, params={"per_page": PER_PAGE, "page": page, "_embed": 1})
        if not resp:
            break
        if total_pages is None:
            total_pages = int(resp.headers.get("X-WP-TotalPages", "0") or 0)
            total = resp.headers.get("X-WP-Total", "?")
            print(f"  REST reports {total} entries across {total_pages or '?'} pages")
        try:
            batch = resp.json()
        except ValueError:
            break
        if not batch:
            break
        entries.extend(batch)
        print(f"  page {page}: {len(batch)} entries (running total {len(entries)})")
        if total_pages and page >= total_pages:
            break
        if len(batch) < PER_PAGE:
            break
        page += 1
    return entries


def normalise_entry(raw: dict) -> dict:
    """Map a raw REST record onto a flat, human-readable dict."""
    record: dict = {
        "id": raw.get("id"),
        "title": strip_html(raw.get("title")),
        "slug": raw.get("slug", ""),
        "url": raw.get("link", ""),
        "date": raw.get("date", ""),
        "modified": raw.get("modified", ""),
        "description": strip_html(raw.get("content")),
        "excerpt": strip_html(raw.get("excerpt")),
    }

    # ACF fields (only present if the site exposes them to REST).
    acf = raw.get("acf")
    if isinstance(acf, dict):
        flat: dict = {}
        flatten("", acf, flat)
        for k, v in flat.items():
            record[f"acf.{k}"] = v

    # Best-effort contact fields from likely ACF key names.
    def first_match(*needles):
        for key, value in record.items():
            if not key.startswith("acf."):
                continue
            low = key.lower()
            if any(n in low for n in needles) and value not in (None, "", []):
                return value
        return ""

    record["email"] = first_match("email")
    record["phone"] = first_match("phone", "telephone", "contact_number", "tel")
    record["website"] = first_match("website", "url", "web")
    record["address"] = first_match("address", "location")
    record["postcode"] = first_match("postcode", "post_code")

    # Embedded taxonomy terms -> category names.
    cats: list[str] = []
    embedded = raw.get("_embedded", {}) or {}
    for group in embedded.get("wp:term", []) or []:
        for term in group:
            name = term.get("name")
            if name:
                cats.append(strip_html(name))
    record["categories"] = "; ".join(sorted(set(cats)))
    record["_raw"] = raw
    return record


# ---------------------------------------------------------------------------
# Sitemap fallback path
# ---------------------------------------------------------------------------

def collect_sitemap_urls(session: requests.Session, base_url: str) -> list[str]:
    """Walk the WordPress core sitemap index and collect directory-entry URLs."""
    index = get(session, urljoin(base_url, "/wp-sitemap.xml"))
    if not index:
        return []
    sub_maps = re.findall(r"<loc>([^<]+)</loc>", index.text)
    entry_urls: list[str] = []
    for sm in sub_maps:
        if "directory" not in sm.lower():
            continue
        page = get(session, sm)
        if not page:
            continue
        entry_urls.extend(re.findall(r"<loc>([^<]+)</loc>", page.text))
    return sorted(set(entry_urls))


def parse_entry_page(session: requests.Session, url: str) -> dict:
    """Best-effort parse of a single listing page for contact details."""
    record = {"url": url, "title": "", "email": "", "phone": "", "website": "",
              "address": "", "postcode": "", "description": "", "categories": "", "_raw": {}}
    resp = get(session, url)
    if not resp or not HAVE_BS4:
        return record
    soup = BeautifulSoup(resp.text, "html.parser")

    if soup.title:
        record["title"] = soup.title.get_text().split(" - ")[0].strip()
    h1 = soup.find("h1")
    if h1:
        record["title"] = h1.get_text(strip=True) or record["title"]

    for a in soup.select('a[href^="mailto:"]'):
        record["email"] = a["href"].replace("mailto:", "").split("?")[0].strip()
        break
    for a in soup.select('a[href^="tel:"]'):
        record["phone"] = a["href"].replace("tel:", "").strip()
        break
    for a in soup.select("a[href]"):
        href = a["href"]
        host = urlparse(href).netloc.lower()
        if host and urlparse(url).netloc.lower() not in host and not any(
            s in host for s in ("facebook", "twitter", "instagram", "linkedin", "youtube", "google")
        ):
            record["website"] = href
            break

    # JSON-LD, if present, often carries address and phone.
    for tag in soup.find_all("script", type="application/ld+json"):
        try:
            data = json.loads(tag.string or "{}")
        except (ValueError, TypeError):
            continue
        blocks = data if isinstance(data, list) else [data]
        for b in blocks:
            if not isinstance(b, dict):
                continue
            addr = b.get("address")
            if isinstance(addr, dict):
                parts = [addr.get(k, "") for k in
                         ("streetAddress", "addressLocality", "addressRegion", "postalCode")]
                record["address"] = ", ".join(p for p in parts if p)
                record["postcode"] = addr.get("postalCode", "") or record["postcode"]
            elif isinstance(addr, str):
                record["address"] = addr
            record["phone"] = record["phone"] or b.get("telephone", "")
    return record


# ---------------------------------------------------------------------------
# Database + exports
# ---------------------------------------------------------------------------

def build_database(records: list[dict], outdir: str) -> str:
    db_path = f"{outdir}/directory.db"
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript("""
        DROP TABLE IF EXISTS entry_categories;
        DROP TABLE IF EXISTS categories;
        DROP TABLE IF EXISTS entries;
        CREATE TABLE entries (
            id INTEGER PRIMARY KEY,
            title TEXT, slug TEXT, url TEXT, date TEXT, modified TEXT,
            email TEXT, phone TEXT, website TEXT, address TEXT, postcode TEXT,
            description TEXT, excerpt TEXT, categories TEXT, raw_json TEXT
        );
        CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
        );
        CREATE TABLE entry_categories (
            entry_id INTEGER, category_id INTEGER,
            PRIMARY KEY (entry_id, category_id)
        );
    """)

    cat_ids: dict[str, int] = {}
    for i, r in enumerate(records):
        entry_id = r.get("id") or (10_000_000 + i)  # synthesise id for sitemap rows
        cur.execute("""
            INSERT OR REPLACE INTO entries
            (id, title, slug, url, date, modified, email, phone, website,
             address, postcode, description, excerpt, categories, raw_json)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            entry_id, r.get("title", ""), r.get("slug", ""), r.get("url", ""),
            r.get("date", ""), r.get("modified", ""), r.get("email", ""),
            r.get("phone", ""), r.get("website", ""), r.get("address", ""),
            r.get("postcode", ""), r.get("description", ""), r.get("excerpt", ""),
            r.get("categories", ""), json.dumps(r.get("_raw", {}), ensure_ascii=False),
        ))
        for cat in [c.strip() for c in r.get("categories", "").split(";") if c.strip()]:
            if cat not in cat_ids:
                cur.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (cat,))
                cur.execute("SELECT id FROM categories WHERE name = ?", (cat,))
                cat_ids[cat] = cur.fetchone()[0]
            cur.execute(
                "INSERT OR IGNORE INTO entry_categories (entry_id, category_id) VALUES (?,?)",
                (entry_id, cat_ids[cat]),
            )
    conn.commit()
    conn.close()
    return db_path


def export_csv_json(records: list[dict], outdir: str) -> tuple[str, str]:
    columns = ["id", "title", "url", "email", "phone", "website", "address",
               "postcode", "categories", "description", "excerpt", "date", "modified"]
    csv_path = f"{outdir}/directory.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for r in records:
            writer.writerow({c: r.get(c, "") for c in columns})

    json_path = f"{outdir}/directory.json"
    clean = [{k: v for k, v in r.items() if k != "_raw"} for r in records]
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump(clean, fh, ensure_ascii=False, indent=2)
    return csv_path, json_path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Export the Involve Kent directory.")
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    ap.add_argument("--outdir", default="data")
    ap.add_argument("--no-html-fallback", action="store_true",
                    help="Skip per-page HTML scraping for entries missing contact details.")
    args = ap.parse_args()

    import os
    os.makedirs(args.outdir, exist_ok=True)
    session = make_session()

    print("Discovering REST endpoint...")
    rest_base = discover_rest_base(session, args.base_url)
    records: list[dict] = []

    if rest_base:
        print(f"Using REST post type rest_base = '{rest_base}'")
        raw_entries = fetch_all_entries(session, args.base_url, rest_base)
        records = [normalise_entry(r) for r in raw_entries]

        # Fill contact gaps from the live page where ACF was not exposed.
        if not args.no_html_fallback and HAVE_BS4:
            missing = [r for r in records if not (r["email"] or r["phone"] or r["website"])]
            if missing:
                print(f"Filling contact gaps for {len(missing)} entries via page parse...")
                for r in missing:
                    if not r.get("url"):
                        continue
                    parsed = parse_entry_page(session, r["url"])
                    for f in ("email", "phone", "website", "address", "postcode"):
                        r[f] = r[f] or parsed.get(f, "")
    else:
        print("REST API unavailable. Falling back to sitemap crawl...")
        urls = collect_sitemap_urls(session, args.base_url)
        print(f"  found {len(urls)} directory URLs in sitemap")
        for i, url in enumerate(urls, 1):
            if i % 25 == 0:
                print(f"  parsed {i}/{len(urls)}")
            records.append(parse_entry_page(session, url))

    if not records:
        print("No records retrieved. The API and sitemap were both unavailable.",
              file=sys.stderr)
        return 1

    db_path = build_database(records, args.outdir)
    csv_path, json_path = export_csv_json(records, args.outdir)

    with_email = sum(1 for r in records if r.get("email"))
    with_phone = sum(1 for r in records if r.get("phone"))
    with_web = sum(1 for r in records if r.get("website"))
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    print("\n" + "=" * 56)
    print(f"Done at {stamp}")
    print(f"  entries retrieved : {len(records)}")
    print(f"  with email        : {with_email}")
    print(f"  with phone        : {with_phone}")
    print(f"  with website      : {with_web}")
    print(f"  SQLite : {db_path}")
    print(f"  CSV    : {csv_path}")
    print(f"  JSON   : {json_path}")
    print("=" * 56)
    return 0


if __name__ == "__main__":
    sys.exit(main())
