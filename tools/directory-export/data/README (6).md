# Involve Kent directory export

Retrieves every listing from the Involve Kent online directory and builds a
database you can query, filter and re-use. Run with the directory owner's
permission only.

## What you get

Each run writes three files into a `data/` folder:

- `directory.db` - SQLite database with three tables: `entries`, `categories`,
  and `entry_categories` (the link between them). Open it with DB Browser for
  SQLite, or import into anything.
- `directory.csv` - one row per listing, for a spreadsheet.
- `directory.json` - the same data as structured JSON.

Every entry keeps its full raw record in the `raw_json` column, so no field is
ever lost even if it is not mapped into a named column.

## How it works

1. It reads the site's own REST schema to find the directory post type, then
   pages through the WordPress REST API 100 records at a time, pulling contact
   fields (ACF) and categories.
2. If any listing is missing an email, phone or website, it opens that listing's
   page and fills the gaps from the page itself.
3. If the REST API is switched off entirely, it falls back to walking the XML
   sitemap and parsing every listing page.

## Running it on GitHub (no local setup needed)

1. Create a new repository on GitHub (via the web UI is fine).
2. Add these three files to the root: `scrape_directory.py`, `requirements.txt`.
3. Add the workflow at `.github/workflows/scrape-directory.yml`
   (the file supplied here as `scrape-directory.yml`).
4. Go to the **Actions** tab, choose **Scrape Involve Kent directory**, and
   click **Run workflow**.
5. When it finishes, download **involve-kent-directory** from the run's
   Artifacts, or find the files committed into the `data/` folder of the repo.

The workflow also re-runs on the 1st of each month so the export stays current.

## Running it locally (optional)

    pip install -r requirements.txt
    python scrape_directory.py

Options:

    --base-url   directory site root (default https://involvekent.org.uk)
    --outdir     output folder (default data)
    --no-html-fallback   skip per-page parsing for entries missing contact details

## A note on the data

Listings are published by charities and community groups. Treat the export as a
signposting resource, keep it in step with the live directory (hence the monthly
re-run), and follow the directory's own terms and conditions for any onward use.
