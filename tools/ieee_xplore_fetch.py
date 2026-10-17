#!/usr/bin/env python3
"""
CLI helper for fetching papers from the IEEE Xplore official API.

This tool complements ``openalex_fetch.py``: OpenAlex ingests IEEE metadata via
DOI indexing (covers nearly all IEEE journal/conference papers), while this
tool hits IEEE Xplore directly for richer metadata fields (abstract, citing
paper count, IEEE index terms, conference location/dates) and is the only one
that returns the ``pdf_url`` for non-OA IEEE papers (requires institutional
access — caller must add their own cookie/auth if needed).

Setup
-----
1. Register for a free academic API key at https://developer.ieee.org/
2. Export the key:

       export IEEE_XPLORE_API_KEY="your-key-here"

The skill calling this script should treat a missing key as a *skip* (warn),
not an error — the whole point of OpenAlex as the fallback is so the skill
still works without IEEE credentials.

Commands
--------
search   Search IEEE Xplore and print results as JSON / human-readable.
get      Fetch one article by IEEE article ID, DOI, or accession number.

Filter flags (search)
---------------------
--year            e.g. "2022", "2020-2024", "2022-"
--content-type    "Journals", "Conferences", "Early Access", "Standards", ...
--publication-title  exact venue name, e.g. "IEEE Transactions on Power Systems"
--author          author last name
--sort            "relevance" | "newest" | "oldest" | "most-popular"
--max             1..200 (default 25; API hard limit 200)

Examples
--------
# Search IEEE TPWRS for LVRT voltage stability papers from 2022 onward
python3 tools/ieee_xplore_fetch.py search \
    '"low voltage ride through" AND "voltage stability"' \
    --publication-title "IEEE Transactions on Power Systems" \
    --year "2022-" --content-type Journals --max 25

# Use boolean / phrase operators in querytext:
#   "AND", "OR", "NOT", parentheses, double-quoted phrases are all supported.

# Fetch a single article by IEEE article number (from any IEEE URL):
python3 tools/ieee_xplore_fetch.py get 8766411

# Or by DOI:
python3 tools/ieee_xplore_fetch.py get 10.1109/TPWRS.2023.123456
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

_API_BASE = "https://ieeexploreapi.ieee.org/api/v1/search/articles"
_USER_AGENT = "ieee-xplore-fetch/1.0 (paper-writing skill)"
_DEFAULT_TIMEOUT = 30

# Content types we commonly use for electrical engineering literature.
_CONTENT_TYPES = (
    "Journals",
    "Conferences",
    "Magazines",
    "Early Access",
    "Books",
    "Standards",
    "Courses",
)

_SORT_FIELD_MAP = {
    "relevance": None,                 # IEEE default: relevance
    "newest": ("publication_year", "desc"),
    "oldest": ("publication_year", "asc"),
    "most-popular": ("citing_paper_count", "desc"),
}


# ──────────────────────────────────────────────────────────────────────────
# HTTP layer
# ──────────────────────────────────────────────────────────────────────────

def _api_key() -> str | None:
    """Return the IEEE Xplore API key from the environment, or None."""
    key = os.getenv("IEEE_XPLORE_API_KEY", "").strip()
    return key or None


def _request_json(url: str, *, retries: int = 2) -> dict[str, Any]:
    """GET ``url`` and return parsed JSON. Retries on 429/5xx with backoff."""
    req = urllib.request.Request(url, headers={
        "User-Agent": _USER_AGENT,
        "Accept": "application/json",
    })
    last_err: Exception | None = None

    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=_DEFAULT_TIMEOUT) as resp:
                raw = resp.read().decode("utf-8")
            return json.loads(raw)
        except urllib.error.HTTPError as exc:
            body = ""
            try:
                body = exc.read().decode("utf-8", errors="replace")
            except Exception:
                pass

            if exc.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(1.5 * (attempt + 1))
                last_err = exc
                continue

            message = f"HTTP {exc.code}"
            if body:
                message += f": {body[:200]}"
            raise RuntimeError(message) from exc
        except urllib.error.URLError as exc:
            if attempt < retries:
                time.sleep(1.5 * (attempt + 1))
                last_err = exc
                continue
            raise RuntimeError(f"Network error: {exc}") from exc
        except json.JSONDecodeError as exc:
            raise RuntimeError("Failed to parse JSON response from IEEE Xplore API") from exc

    raise RuntimeError(f"Request failed after retries: {last_err}")


# ──────────────────────────────────────────────────────────────────────────
# Parsing helpers
# ──────────────────────────────────────────────────────────────────────────

def _clean(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        text = value.strip().replace("\n", " ")
        return text or None
    return value


def _parse_authors(authors_block: Any) -> list[dict[str, Any]]:
    """IEEE returns authors as a list of {author_order, full_name} dicts."""
    if not isinstance(authors_block, list):
        return []
    result = []
    for entry in authors_block:
        if isinstance(entry, dict):
            result.append({
                "name": _clean(entry.get("full_name")),
                "order": entry.get("author_order"),
            })
        elif isinstance(entry, str):
            result.append({"name": _clean(entry), "order": None})
    return result


def _parse_index_terms(index_block: Any) -> dict[str, list[str]]:
    """IEEE returns index_terms as {Author Keywords: [...], IEEE Terms: [...], ...}."""
    if not isinstance(index_block, dict):
        return {}
    out: dict[str, list[str]] = {}
    for k, v in index_block.items():
        if isinstance(v, list):
            out[str(k)] = [_clean(x) for x in v if _clean(x)]
        elif isinstance(v, str):
            out[str(k)] = [s.strip() for s in v.split(";") if s.strip()]
    return out


def _parse_article(article: dict[str, Any]) -> dict[str, Any]:
    return {
        "article_number": article.get("article_number"),
        "title": _clean(article.get("title")),
        "abstract": _clean(article.get("abstract")),
        "doi": _clean(article.get("doi")),
        "html_url": _clean(article.get("html_url")),
        "pdf_url": _clean(article.get("pdf_url")),
        "authors": _parse_authors(article.get("authors")),
        "publication_year": article.get("publication_year"),
        "publication_date": _clean(article.get("publication_date")),
        "volume": _clean(article.get("volume")),
        "issue": _clean(article.get("issue")),
        "start_page": _clean(article.get("start_page")),
        "end_page": _clean(article.get("end_page")),
        "publisher": _clean(article.get("publisher")),
        "content_type": _clean(article.get("content_type")),
        "venue": _clean(article.get("publication_title")),
        "venue_identifier": _clean(article.get("publication_venue_number")),
        "conference_location": _clean(article.get("conference_location")),
        "conference_dates": _clean(article.get("conference_dates")),
        "citing_paper_count": article.get("citing_paper_count"),
        "downloaded": article.get("downloaded"),
        "index_terms": _parse_index_terms(article.get("index_terms")),
    }


# ──────────────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────────────

def search(
    query: str,
    *,
    max_results: int = 25,
    start_record: int = 1,
    year: str | None = None,
    content_type: str | None = None,
    publication_title: str | None = None,
    author: str | None = None,
    sort: str = "relevance",
) -> dict[str, Any]:
    """Search IEEE Xplore. Returns the raw API envelope plus parsed articles."""
    key = _api_key()
    if not key:
        raise RuntimeError(
            "IEEE_XPLORE_API_KEY is not set. Register a free academic key at "
            "https://developer.ieee.org/ and `export IEEE_XPLORE_API_KEY=...`. "
            "If you don't have one, the calling skill should fall back to OpenAlex."
        )

    params: dict[str, Any] = {
        "apikey": key,
        "querytext": query,
        "max_records": max(1, min(int(max_results), 200)),
        "start_record": max(1, int(start_record)),
        "sort_field": "relevance",
        "sort_order": "desc",
    }
    if year:
        params["publication_year"] = year
    if content_type:
        if content_type not in _CONTENT_TYPES:
            raise ValueError(
                f"Unknown content_type {content_type!r}. "
                f"Expected one of: {', '.join(_CONTENT_TYPES)}"
            )
        params["content_type"] = content_type
    if publication_title:
        params["publication_title"] = publication_title
    if author:
        params["author"] = author

    sort_pair = _SORT_FIELD_MAP.get(sort)
    if sort_pair:
        params["sort_field"], params["sort_order"] = sort_pair

    url = f"{_API_BASE}?{urllib.parse.urlencode(params)}"
    payload = _request_json(url)
    articles = payload.get("articles") or []

    return {
        "mode": "search",
        "total_records": payload.get("total_records"),
        "total_searched": payload.get("total_searched"),
        "start_record": payload.get("start_records", start_record),
        "next_start_record": (
            start_record + len(articles) if articles else None
        ),
        "data": [_parse_article(a) for a in articles],
    }


def get_article(article_id: str) -> dict[str, Any]:
    """Fetch a single article by IEEE article number, DOI, or accession number.

    IEEE Xplore API treats ``article_number`` as the canonical ID — if you pass
    a DOI, it auto-resolves.
    """
    key = _api_key()
    if not key:
        raise RuntimeError("IEEE_XPLORE_API_KEY is not set.")

    params = {
        "apikey": key,
        "article_number": article_id,
    }
    url = f"{_API_BASE}?{urllib.parse.urlencode(params)}"
    payload = _request_json(url)
    article = (payload.get("articles") or [None])[0]
    if not article:
        raise RuntimeError(f"No article found for identifier: {article_id}")
    return _parse_article(article)


# ──────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────

def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Search and fetch papers from IEEE Xplore official API.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # search
    sp = subparsers.add_parser(
        "search",
        help="Search IEEE Xplore.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s "voltage stability" --max 10
  %(prog)s '"LVRT" AND "voltage stability"' \\
      --publication-title "IEEE Transactions on Power Systems" \\
      --year "2022-" --content-type Journals --max 25
  %(prog)s "grid-forming converter" --year "2022-" --max 15
        """,
    )
    sp.add_argument("query", help="Search query (IEEE Xplore query syntax supports "
                                  "AND / OR / NOT, parentheses, and \"phrase\" quoting)")
    sp.add_argument("--max", type=int, default=25,
                    help="Max results (1..200, default 25)")
    sp.add_argument("--start", type=int, default=1,
                    help="Start record (pagination, default 1)")
    sp.add_argument("--year",
                    help="Year filter, e.g. '2022', '2020-2024', '2022-'")
    sp.add_argument("--content-type", choices=list(_CONTENT_TYPES),
                    help="IEEE content type filter")
    sp.add_argument("--publication-title",
                    help="Exact venue name, e.g. 'IEEE Transactions on Power Systems'")
    sp.add_argument("--author", help="Author last name")
    sp.add_argument("--sort",
                    choices=list(_SORT_FIELD_MAP.keys()),
                    default="relevance",
                    help="Sort order (default: relevance)")
    sp.add_argument("--json", action="store_true", help="Output JSON to stdout")

    # get
    gp = subparsers.add_parser(
        "get",
        help="Fetch one article by IEEE article number or DOI.",
    )
    gp.add_argument("article_id",
                    help="IEEE article number (from any ieeexplore.ieee.org URL) "
                         "or DOI (e.g., 10.1109/TPWRS.2023.123456)")
    gp.add_argument("--json", action="store_true", help="Output JSON to stdout")

    return parser


def _print_human(articles: list[dict[str, Any]], total: int | None) -> None:
    print(f"Found {len(articles)} articles (total: {total if total is not None else '?'}):\n")
    for i, a in enumerate(articles, 1):
        title = a.get("title") or "(no title)"
        print(f"{i}. {title}")
        names = [au.get("name") for au in (a.get("authors") or []) if au.get("name")]
        if names:
            print(f"   Authors: {', '.join(names[:5])}{' et al.' if len(names) > 5 else ''}")
        venue = a.get("venue") or a.get("content_type")
        print(f"   Year: {a.get('publication_year')} | Venue: {venue}")
        if a.get("publisher"):
            print(f"   Publisher: {a['publisher']}")
        cites = a.get("citing_paper_count")
        if cites is not None:
            print(f"   Citations: {cites}")
        if a.get("doi"):
            print(f"   DOI: {a['doi']}")
        if a.get("pdf_url"):
            print(f"   PDF: {a['pdf_url']}")
        elif a.get("html_url"):
            print(f"   HTML: {a['html_url']}")
        if a.get("index_terms"):
            kw = a["index_terms"].get("Author Keywords") or a["index_terms"].get("IEEE Terms")
            if kw:
                print(f"   Keywords: {', '.join(kw[:6])}")
        if a.get("abstract"):
            preview = a["abstract"][:200] + "..." if len(a["abstract"]) > 200 else a["abstract"]
            print(f"   Abstract: {preview}")
        print()


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "search":
            result = search(
                args.query,
                max_results=args.max,
                start_record=args.start,
                year=args.year,
                content_type=args.content_type,
                publication_title=args.publication_title,
                author=args.author,
                sort=args.sort,
            )
            if args.json:
                print(json.dumps(result, indent=2, ensure_ascii=False))
            else:
                _print_human(result["data"], result.get("total_records"))
            return 0

        if args.command == "get":
            article = get_article(args.article_id)
            if args.json:
                print(json.dumps(article, indent=2, ensure_ascii=False))
            else:
                _print_human([article], 1)
            return 0

        parser.print_help()
        return 1

    except RuntimeError as exc:
        # Missing API key, network error, HTTP error → warn-and-skip in the
        # calling skill, but here we surface the message to stderr with a
        # non-zero exit so the skill can detect failure.
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())