#!/usr/bin/env python3
"""Extract auditable metadata and first-page text from a local research PDF."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

try:
    from pypdf import PdfReader
except ImportError as exc:  # pragma: no cover - depends on the user's runtime
    raise SystemExit(
        "pypdf is required for local PDF extraction. Run: pip install -r requirements.txt"
    ) from exc


DOI_RE = re.compile(r"\b10\.\d(?:\s*\d){3,8}/[-._;()/:A-Z0-9]+", re.IGNORECASE)
YEAR_RE = re.compile(r"\b(?:19|20)\d{2}\b")
ABSTRACT_RE = re.compile(
    r"\babstract\b\s*[:.-]?\s*(.{80,5000}?)(?=\n\s*(?:index terms|keywords|i\.\s+introduction|1\.\s+introduction)\b|\Z)",
    re.IGNORECASE | re.DOTALL,
)


def _clean(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()


def extract_pdf(path: str | Path, *, max_pages: int = 2, max_chars: int = 8000) -> dict[str, Any]:
    pdf_path = Path(path)
    result: dict[str, Any] = {
        "file": str(pdf_path),
        "extraction_status": "failed",
        "pages": None,
        "title": None,
        "authors": [],
        "year": None,
        "doi": None,
        "abstract": None,
        "text_excerpt": "",
        "reason": None,
    }
    if not pdf_path.is_file():
        result["reason"] = "file_not_found"
        return result

    try:
        reader = PdfReader(str(pdf_path))
        result["pages"] = len(reader.pages)
        chunks: list[str] = []
        for page in reader.pages[: max(1, max_pages)]:
            text = page.extract_text() or ""
            if text:
                chunks.append(text)
        excerpt = _clean("\n".join(chunks))[:max_chars]
        result["text_excerpt"] = excerpt
        metadata = reader.metadata or {}
        title = _clean(metadata.get("/Title"))
        author = _clean(metadata.get("/Author"))
        if title:
            result["title"] = title
        if author:
            result["authors"] = [a.strip() for a in re.split(r"[;,]", author) if a.strip()]
        doi = DOI_RE.search(excerpt)
        if doi:
            result["doi"] = re.sub(r"\s+", "", doi.group(0)).rstrip(".,;)")
        years = YEAR_RE.findall(excerpt)
        if years:
            result["year"] = int(years[0])
        abstract = ABSTRACT_RE.search(excerpt)
        if abstract:
            result["abstract"] = _clean(abstract.group(1))
        result["extraction_status"] = "text_extracted" if excerpt else "no_extractable_text"
        if not excerpt:
            result["reason"] = "scanned_or_protected_pdf"
    except Exception as exc:  # corrupted/encrypted PDFs must not stop a survey
        result["reason"] = f"{type(exc).__name__}: {exc}"
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file")
    parser.add_argument("--max-pages", type=int, default=2)
    parser.add_argument("--max-chars", type=int, default=8000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    result = extract_pdf(args.file, max_pages=args.max_pages, max_chars=args.max_chars)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(result["extraction_status"])
        print(result["text_excerpt"])
    return 0 if result["extraction_status"] != "failed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
