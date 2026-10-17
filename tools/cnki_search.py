#!/usr/bin/env python3
"""
中文文献检索（CNKI / 万方 / 维普 兜底）。

CNKI 没有开放 API，万方 / 维普 也都需要机构订阅。这个工具不抓全文（会被
CAPTCHA 拦截），而是借助 DuckDuckGo HTML 的 ``site:<domain>`` 限定搜索把
"标题、URL、片段"拉回来，**只在没有 arXiv ID / DOI 的中文论文上作为兜底来源**
使用，配合 `verify_papers.py` 走 CrossRef 标题模糊匹配层。

⚠️ 现实约束（务必让调用方理解）：
- DuckDuckGo HTML rate-limit 比较激进（短时间内多次访问会返回 CAPTCHA 跳
  转或直接空结果），这是预期状况，不算脚本坏了
- 多数 CNKI/万方/维普 论文 PDF 是付费墙，**不要硬塞任何 fake PDF 链接**
- 输出的 status 一律是 ``paywall_cnki`` / ``paywall_wanfang`` /
  ``paywall_cqvip`` / ``unverified_paywall`` —— 调用方在
  ``skills/research-lit`` Step 1.7 里按 PAYWALL 标签处理

Commands
--------
search  按 site 限定搜索中文数据库。

Source flags (--source)
-----------------------
- ``cnki``   默认，搜索 site:cnki.net / site:kns.cnki.net / site:cnki.com.cn
- ``wanfang`` 搜索 site:wanfangdata.com.cn
- ``cqvip``   搜索 site:cqvip.com

Examples
--------
python3 tools/cnki_search.py search "新能源并网 低电压穿越 静态电压稳定" --max 10
python3 tools/cnki_search.py search "阻抗建模 宽频振荡 变流器" --source wanfang --max 8
python3 tools/cnki_search.py search "神经网络 电力系统 连续潮流" --source cqvip --max 8
python3 tools/cnki_search.py search "新能源 LVRT" --json > cnki_results.json
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

_DDG_HTML = "https://html.duckduckgo.com/html/"
_USER_AGENTS = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
)
_DEFAULT_TIMEOUT = 30
_STATUS_BY_SOURCE = {
    "cnki": "paywall_cnki",
    "wanfang": "paywall_wanfang",
    "cqvip": "paywall_cqvip",
}

_SITE_FILTERS = {
    "cnki": "site:cnki.net OR site:kns.cnki.net OR site:cnki.com.cn",
    "wanfang": "site:wanfangdata.com.cn",
    "cqvip": "site:cqvip.com",
}

# Heuristics to extract venue / authors / year from the snippet when DuckDuckGo
# surfaces them inline. These are best-effort; if the snippet doesn't include
# the field, leave it null.
_YEAR_RE = re.compile(r"(?:19|20)\d{2}")
_DOI_RE = re.compile(r"\b10\.\d{4,9}/[^\s<>\"]+", re.IGNORECASE)
_ARXIV_RE = re.compile(r"\b(?:arXiv:)?(\d{4}\.\d{4,5}(?:v\d+)?)\b", re.IGNORECASE)


# ──────────────────────────────────────────────────────────────────────────
# HTTP layer
# ──────────────────────────────────────────────────────────────────────────

def _request_html(url: str, *, retries: int = 2) -> str:
    """GET a DuckDuckGo HTML search page and return the raw HTML body."""
    req = urllib.request.Request(url, headers={
        "User-Agent": random.choice(_USER_AGENTS),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        "Accept-Encoding": "identity",  # avoid gzip so we can use stdlib decoder
        "Connection": "close",
    })
    last_err: Exception | None = None
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=_DEFAULT_TIMEOUT) as resp:
                # Be permissive on encoding detection — DDG sometimes lies about charset.
                raw = resp.read()
            # Try utf-8 first, then gb18030 for CNKI results that leak Chinese encoding.
            for enc in ("utf-8", "gb18030"):
                try:
                    return raw.decode(enc)
                except UnicodeDecodeError:
                    continue
            return raw.decode("utf-8", errors="replace")
        except urllib.error.HTTPError as exc:
            # 202 (DDG's "still searching" response) → retry once
            if exc.code == 202 and attempt < retries:
                time.sleep(1.5 * (attempt + 1))
                continue
            if exc.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(2.0 * (attempt + 1))
                last_err = exc
                continue
            raise RuntimeError(f"HTTP {exc.code} from DDG") from exc
        except urllib.error.URLError as exc:
            if attempt < retries:
                time.sleep(1.5 * (attempt + 1))
                last_err = exc
                continue
            raise RuntimeError(f"Network error: {exc}") from exc
    raise RuntimeError(f"DDG request failed after retries: {last_err}")


def _search_ddg(query: str, *, site_filter: str, max_results: int) -> list[str]:
    """Hit DuckDuckGo HTML and return a list of raw HTML result blocks.

    Returns an empty list if the search failed or returned no real results
    (e.g., CAPTCHA page).
    """
    full_query = f"{site_filter} {query}"
    url = f"{_DDG_HTML}?{urllib.parse.urlencode({'q': full_query, 'kl': 'cn-zh'})}"
    html = _request_html(url)
    # CAPTCHA / bot-challenge pages contain these markers — bail out cleanly so
    # the calling skill doesn't treat them as legitimate results.
    lower = html.lower()
    if ("captcha" in lower and "robot" in lower) or "anomaly" in lower or "duckduckgo.com/?q=" not in lower and "no-results" in lower:
        # Some legitimate pages also lack /?q=; only treat as CAPTCHA if it's also short and lacks results.
        if len(html) < 5000:
            return []
    # Each result block sits inside a <div ... class="result ...">…</div>
    # Use a permissive regex so we don't break on DDG's frequent class tweaks.
    blocks = re.findall(
        r'<div[^>]*class="[^"]*\bresult\b[^"]*"[^>]*>(.*?)(?=<div[^>]*class="[^"]*\bresult\b|<div[^>]*class="[^"]*\bnav-wrap\b|</main>|</body>)',
        html,
        re.DOTALL | re.IGNORECASE,
    )
    return blocks[:max_results]


# ──────────────────────────────────────────────────────────────────────────
# Parsing
# ──────────────────────────────────────────────────────────────────────────

_TAG_RE = re.compile(r"<[^>]+>")
_WHITESPACE_RE = re.compile(r"\s+")
_HREF_RE = re.compile(r'href="([^"]+)"', re.IGNORECASE)


def _strip_html(text: str) -> str:
    text = _TAG_RE.sub(" ", text or "")
    # Decode common HTML entities (only the ones DDG emits in result blocks).
    text = (text.replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", '"')
                .replace("&#39;", "'")
                .replace("&nbsp;", " "))
    return _WHITESPACE_RE.sub(" ", text).strip()


def _extract_title_and_url(block: str) -> tuple[str | None, str | None]:
    """Pull title text + href out of a DDG result block."""
    # DDG wraps the title in <a class="result__a" href="...">Title</a>
    m = re.search(
        r'<a[^>]*class="[^"]*\bresult__a\b[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        block,
        re.DOTALL | re.IGNORECASE,
    )
    if not m:
        # Fallback: any <a> that looks like a top-level result link
        m = re.search(r'<a[^>]*href="(https?://[^"]+)"[^>]*>(.*?)</a>', block, re.DOTALL)
    if not m:
        return None, None
    href = m.group(1)
    # DDG sometimes wraps URLs in /l/?uddg=<encoded>. Decode that.
    if "duckduckgo.com/l/?" in href or "uddg=" in href:
        parsed = urllib.parse.urlparse(href)
        qs = urllib.parse.parse_qs(parsed.query)
        if "uddg" in qs:
            href = qs["uddg"][0]
    return _strip_html(m.group(2)), href


def _extract_snippet(block: str) -> str | None:
    m = re.search(
        r'<a[^>]*class="[^"]*\bresult__snippet\b[^"]*"[^>]*>(.*?)</a>',
        block,
        re.DOTALL | re.IGNORECASE,
    )
    if not m:
        m = re.search(r'<td[^>]*class="[^"]*\bsnippet\b[^"]*"[^>]*>(.*?)</td>',
                      block, re.DOTALL | re.IGNORECASE)
    if not m:
        return None
    return _strip_html(m.group(1)) or None


def _extract_field(snippet: str | None, regex: re.Pattern) -> str | None:
    if not snippet:
        return None
    m = regex.search(snippet)
    return m.group(0) if m else None


def parse_block(block: str, source: str) -> dict[str, Any] | None:
    """Convert one DDG result block into a normalized record."""
    title, url = _extract_title_and_url(block)
    if not title or not url:
        return None
    snippet = _extract_snippet(block)
    return {
        "title": title,
        "url": url,
        "snippet": snippet,
        "source": source,
        "year": _extract_field(snippet, _YEAR_RE),
        "doi": _extract_field(snippet, _DOI_RE),
        "arxiv_id": _extract_field(snippet, _ARXIV_RE),
        "status": _STATUS_BY_SOURCE.get(source, "paywall_unknown"),
    }


# ──────────────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────────────

def search(query: str, *, max_results: int = 10, source: str = "cnki") -> dict[str, Any]:
    """Search a Chinese academic database via DuckDuckGo HTML site: filter.

    Returns:
        {
            "source": "cnki" | "wanfang" | "cqvip",
            "site_filter": "site:cnki.net ...",
            "query": "...",
            "raw_blocks": <int>,         # raw DDG blocks matched (before parsing)
            "data": [
                {"title": "...", "url": "...", "snippet": "...",
                 "year": "2022", "doi": null, "arxiv_id": null,
                 "source": "cnki", "status": "paywall_cnki"},
                ...
            ]
        }
    """
    if source not in _SITE_FILTERS:
        raise ValueError(f"Unknown source {source!r}. "
                         f"Expected one of: {', '.join(_SITE_FILTERS.keys())}")
    site_filter = _SITE_FILTERS[source]
    blocks = _search_ddg(query, site_filter=site_filter, max_results=max_results)
    parsed: list[dict[str, Any]] = []
    for block in blocks:
        rec = parse_block(block, source)
        if rec:
            parsed.append(rec)
    return {
        "source": source,
        "site_filter": site_filter,
        "query": query,
        "raw_blocks": len(blocks),
        "data": parsed,
    }


# ──────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────

def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Search Chinese academic databases (CNKI / Wanfang / CQVIP) "
                    "via DuckDuckGo HTML site: filter. Best-effort: returns "
                    "title/URL/snippet only; paywall/PDF access is out of scope.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    sp = subparsers.add_parser("search", help="Search Chinese databases.")
    sp.add_argument("query", help="Chinese query string (e.g. '新能源并网 静态电压稳定')")
    sp.add_argument("--source", choices=list(_SITE_FILTERS.keys()), default="cnki",
                    help="Database (default: cnki)")
    sp.add_argument("--max", type=int, default=10,
                    help="Max results to return (default: 10)")
    sp.add_argument("--json", action="store_true", help="Emit JSON to stdout")

    return parser


def _print_human(result: dict[str, Any]) -> None:
    print(f"[{result['source']}] site: {result['site_filter']}")
    print(f"Query: {result['query']}")
    print(f"Raw DDG blocks: {result['raw_blocks']}, parsed: {len(result['data'])}\n")
    for i, rec in enumerate(result["data"], 1):
        print(f"{i}. {rec['title']}")
        print(f"   URL: {rec['url']}")
        if rec.get("year"):
            print(f"   Year: {rec['year']}")
        if rec.get("doi"):
            print(f"   DOI: {rec['doi']}")
        if rec.get("arxiv_id"):
            print(f"   arXiv: {rec['arxiv_id']}")
        if rec.get("snippet"):
            preview = rec["snippet"]
            if len(preview) > 240:
                preview = preview[:240] + "..."
            print(f"   Snippet: {preview}")
        print(f"   Status: {rec['status']}")
        print()


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "search":
            result = search(args.query, max_results=args.max, source=args.source)
            if args.json:
                print(json.dumps(result, indent=2, ensure_ascii=False))
            else:
                _print_human(result)
            return 0

        parser.print_help()
        return 1

    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())