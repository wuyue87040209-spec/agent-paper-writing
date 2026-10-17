#!/usr/bin/env python3
"""
本地论文库扫描器 — 电气领域研究文献 skill 的 Step 0 工具。

约定
----
- 本地论文库默认根目录是 ``CSPS老师期刊论文收集/``，下面按老师姓名分文件夹
  （``胡家兵老师论文汇总/``、``李英彪老师论文汇总/``、``占萌老师论文汇总/`` …）。
- 同一篇论文经常在多位老师文件夹下重复出现（合著者）；按"标准化文件名"去重。
- 文件名约定：``<标题>_<作者或期刊信息>.pdf``（中文期刊常含中文空格与符号）。

本脚本做四件事：
1. 按文件夹的**优先级预算**（默认 胡家兵 12 : 李英彪 6 : 占萌/何维/袁小明/其他 2）
   切分候选池，避免默认全收胡家兵的论文导致其他老师论文永远进不去精读列表。
2. 用关键词列表给每篇 PDF 打"相关性分"，组内按相关性降序选 Top-N。
3. 跨老师文件夹去重：先到的文件夹保留，后到的若"标准化标题"已收录则跳过。
4. 输出 JSON：``[{priority, teacher, file, title_from_filename, relevance_score,
   matched_keywords}, ...]``，交给 SKILL.md Step 0 后续 ``Read`` 精读。

CLI
---

  python3 local_paper_scan.py scan \\
      --library "CSPS老师期刊论文收集" \\
      --max 20 \\
      --budget "胡家兵老师论文汇总:12,李英彪老师论文汇总:6,占萌老师论文汇总:2" \\
      --keywords "新能源并网 静态电压稳定 连续潮流 LVRT 阻抗 变流器"

  # 不指定 --max 时用 sum(budget)；不指定 --budget 时回退到默认 12:6:剩余。

  # 只列出文件清单（不排序、不预算截断），用于 debug：
  python3 local_paper_scan.py list --library "CSPS老师期刊论文收集"

  # 看预算与优先级映射：
  python3 local_paper_scan.py schema

设计原则
--------
- **预算总和不强制等于 --max**：未分配的文件夹平均分配剩余预算；
  也不允许总预算超过 --max，自动按比例缩放。
- **优先级贪心**：胡家兵老师文件夹里的论文（按相关性排序）取满 12 篇；
  满了之后才进李英彪老师文件夹。避免低优先级的论文被高优先级的高分论文挤出。
- **去重稳健**：跨文件夹的"标准化标题"用 NFKD + 去标点 + 折叠空白 做指纹，
  相同指纹视为同一篇。
- **优雅降级**：library 目录不存在、文件夹为空、关键词无命中都不算错误，
  返回空 data；调用方按 warn-and-skip 处理。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

# 默认文件夹优先级顺序（高 → 低）；调用方可以用 --budget 覆盖其中任意几项。
# 出现在 library 根目录下但不在此表的文件夹，按字母序追加到末尾，等同于
# "其他"。
DEFAULT_PRIORITY_ORDER = (
    "胡家兵老师论文汇总",
    "李英彪老师论文汇总",
    "占萌老师论文汇总",
    "何维老师论文汇总",
    "袁小明老师论文汇总",
)

# 默认预算（按 DEFAULT_PRIORITY_ORDER 顺序）。
DEFAULT_BUDGET = "胡家兵老师论文汇总:12,李英彪老师论文汇总:6,占萌老师论文汇总:2"

_PDF_SUFFIX = ".pdf"
_NON_TITLE_CHARS = re.compile(r"[^\w\s\u4e00-\u9fff]", re.UNICODE)
_WHITESPACE_RE = re.compile(r"\s+")


# ──────────────────────────────────────────────────────────────────────────
# Data shapes
# ──────────────────────────────────────────────────────────────────────────

@dataclass
class Candidate:
    teacher: str
    file_path: str
    file_name: str
    title_from_filename: str
    fingerprint: str
    relevance_score: float
    matched_keywords: list[str] = field(default_factory=list)


@dataclass
class ScannedRecord:
    priority: int          # 1-based, 越小越优先
    teacher: str
    file: str              # path relative to library root, POSIX style
    title_from_filename: str
    relevance_score: float
    matched_keywords: list[str]


# ──────────────────────────────────────────────────────────────────────────
# Filename / relevance helpers
# ──────────────────────────────────────────────────────────────────────────

def parse_title_from_filename(file_name: str) -> str:
    """Extract the human-readable title from ``<标题>_<作者或期刊信息>.pdf``.

    We don't know the delimiter precisely (sometimes ``_`` is part of the title
    itself, sometimes it's a separator), so we use heuristics:
    1. Drop the .pdf suffix.
    2. If the last token is "Author" / "et al" / looks like a year / contains
       only ASCII letters, treat it as a separator boundary.
    3. Otherwise keep the full string as the title.
    """
    stem = file_name[: -len(_PDF_SUFFIX)] if file_name.lower().endswith(_PDF_SUFFIX) else file_name
    # Heuristic: if there's at least one "_" and the part after the last "_"
    # doesn't look like part of the title (no Chinese, only short ASCII tokens),
    # split there.
    if "_" in stem:
        prefix, last = stem.rsplit("_", 1)
        last_stripped = last.strip()
        # If the last token is short, ascii-only, and looks like a surname/year,
        # we treat "_" as the separator.
        if (last_stripped
                and len(last_stripped) <= 30
                and not re.search(r"[\u4e00-\u9fff]", last_stripped)
                and (re.fullmatch(r"[A-Za-z][A-Za-z\.\-']{0,30}", last_stripped)
                     or re.fullmatch(r"(19|20)\d{2}.*", last_stripped)
                     or re.fullmatch(r"et[\s_]*al.*", last_stripped, re.IGNORECASE))):
            stem = prefix
    return stem.strip()


def title_fingerprint(title: str) -> str:
    """Normalize a title for cross-folder dedup.

    NFKD + lowercase + drop non-word/non-CJK + collapse whitespace.
    """
    if not title:
        return ""
    t = unicodedata.normalize("NFKD", title).lower()
    t = _NON_TITLE_CHARS.sub(" ", t)
    t = _WHITESPACE_RE.sub(" ", t).strip()
    return t


def relevance_score(title: str, keywords: list[str]) -> tuple[float, list[str]]:
    """Score a title against a list of keywords.

    Each keyword contributes 1.0 if it's a substring of the normalized title.
    Length normalization prevents very short titles from artificially looking
    super relevant. Returns (score, matched_keywords).
    """
    norm = title_fingerprint(title)
    if not norm or not keywords:
        return 0.0, []
    matched: list[str] = []
    score = 0.0
    for kw in keywords:
        kw_norm = title_fingerprint(kw)
        if not kw_norm:
            continue
        if kw_norm in norm:
            matched.append(kw)
            # Heavier weight for longer keywords (more specific intent).
            score += 1.0 + min(len(kw_norm), 12) / 12.0
    if not matched:
        return 0.0, []
    # Length normalization: short titles with one hit can saturate fast;
    # divide by sqrt(title-len) so very long titles don't get unfairly penalized.
    norm_score = score / max(1.0, (len(norm) ** 0.5))
    return round(norm_score, 4), matched


# ──────────────────────────────────────────────────────────────────────────
# Budget / priority parsing
# ──────────────────────────────────────────────────────────────────────────

def parse_budget(spec: str | None, *, max_total: int | None,
                 known_folders: list[str]) -> dict[str, int]:
    """Parse a ``"folder:n,folder:n,..."`` spec into ``{folder: n}``.

    Behavior:
    - Folders not listed in the spec (but present in the library) get an equal
      share of the remaining budget, capped by max_total.
    - If the spec sums to more than max_total, scale all entries proportionally
      so the total equals max_total (rounded down, residual goes to the highest
      priority folder).
    """
    budget: dict[str, int] = {}

    if spec:
        for chunk in spec.split(","):
            chunk = chunk.strip()
            if not chunk or ":" not in chunk:
                continue
            folder, _, n_str = chunk.partition(":")
            folder = folder.strip()
            try:
                n = int(n_str.strip())
            except ValueError:
                continue
            if folder and n >= 0:
                budget[folder] = budget.get(folder, 0) + n

    # Unknown folders (in library but not in spec) get equal share of residual.
    unknown = [f for f in known_folders if f not in budget]
    if unknown:
        total_spec = sum(budget.values())
        residual: int | None = None
        if max_total is not None:
            residual = max(0, max_total - total_spec)
        if residual is None or residual > 0:
            per = max(0, (residual or 0) // max(1, len(unknown)))
            for f in unknown:
                budget.setdefault(f, per)
            # Distribute leftover 1-by-1 to early folders to avoid losing slots.
            if residual is not None:
                leftover = residual - per * len(unknown)
                for f in unknown[: max(0, leftover)]:
                    budget[f] = budget.get(f, 0) + 1
        else:
            for f in unknown:
                budget.setdefault(f, 0)

    # Scale down if total exceeds max_total.
    if max_total is not None:
        total = sum(budget.values())
        if total > max_total > 0:
            scale = max_total / total
            scaled = {f: int(v * scale) for f, v in budget.items()}
            residual = max_total - sum(scaled.values())
            # Give residual to the highest-priority folder (first in input order).
            ordered = sorted(
                scaled.keys(),
                key=lambda f: (known_folders.index(f) if f in known_folders else 10_000),
            )
            for f in ordered:
                if residual <= 0:
                    break
                scaled[f] += 1
                residual -= 1
            budget = scaled

    # Drop zero/negative entries.
    return {f: n for f, n in budget.items() if n > 0}


# ──────────────────────────────────────────────────────────────────────────
# Core scan
# ──────────────────────────────────────────────────────────────────────────

def list_pdfs(library_root: Path) -> list[Path]:
    """Return all *.pdf under ``library_root`` (recursive, one level deep)."""
    if not library_root.is_dir():
        return []
    return sorted(p for p in library_root.rglob("*.pdf") if p.is_file())


def _priority_index(folder: str, known_order: list[str]) -> int:
    try:
        return known_order.index(folder)
    except ValueError:
        return len(known_order)


def scan(
    library_root: str | Path,
    *,
    max_total: int | None = 20,
    budget_spec: str | None = DEFAULT_BUDGET,
    keywords: list[str] | None = None,
) -> list[ScannedRecord]:
    """Run the full scan pipeline; return ordered records ready for SKILL.md Step 0."""
    keywords = keywords or []
    root = Path(library_root)
    if not root.is_dir():
        return []

    pdfs = list_pdfs(root)
    if not pdfs:
        return []

    # Bucket PDFs by teacher folder (relative path's first segment).
    by_teacher: dict[str, list[Path]] = defaultdict(list)
    for pdf in pdfs:
        try:
            rel = pdf.relative_to(root)
        except ValueError:
            continue
        parts = rel.parts
        teacher = parts[0] if len(parts) > 1 else "<root>"
        by_teacher[teacher].append(pdf)

    known_folders = list(by_teacher.keys())
    budget = parse_budget(budget_spec, max_total=max_total, known_folders=known_folders)

    # Stable priority order: folders explicitly listed in budget first (by
    # DEFAULT_PRIORITY_ORDER if present), then everything else alphabetically.
    explicit = list(budget.keys())
    explicit_sorted = sorted(
        explicit,
        key=lambda f: _priority_index(f, list(DEFAULT_PRIORITY_ORDER)),
    )
    other = sorted(f for f in known_folders if f not in explicit)
    folder_order = explicit_sorted + other

    seen_fingerprints: set[str] = set()
    out: list[ScannedRecord] = []
    priority_counter = 0

    for teacher in folder_order:
        cap = budget.get(teacher, 0)
        if cap <= 0:
            continue

        candidates: list[Candidate] = []
        for pdf in by_teacher[teacher]:
            title = parse_title_from_filename(pdf.name)
            fp = title_fingerprint(title)
            score, matched = relevance_score(title, keywords)
            candidates.append(Candidate(
                teacher=teacher,
                file_path=str(pdf),
                file_name=pdf.name,
                title_from_filename=title,
                fingerprint=fp,
                relevance_score=score,
                matched_keywords=matched,
            ))

        # Sort: relevance desc, then path asc (deterministic tiebreaker).
        candidates.sort(key=lambda c: (-c.relevance_score, c.file_path))

        chosen = 0
        for cand in candidates:
            if chosen >= cap:
                break
            if not cand.fingerprint:
                continue
            if cand.fingerprint in seen_fingerprints:
                continue
            seen_fingerprints.add(cand.fingerprint)
            priority_counter += 1
            out.append(ScannedRecord(
                priority=priority_counter,
                teacher=teacher,
                file=cand.file_path,
                title_from_filename=cand.title_from_filename,
                relevance_score=cand.relevance_score,
                matched_keywords=cand.matched_keywords,
            ))
            chosen += 1

    return out


# ──────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────

def _emit_json(obj: object) -> None:
    print(json.dumps(obj, indent=2, ensure_ascii=False))


def cmd_scan(args: argparse.Namespace) -> int:
    keywords = [k for k in (args.keywords or "").split() if k] if isinstance(args.keywords, str) else list(args.keywords or [])
    budget_spec = args.budget if args.budget else DEFAULT_BUDGET
    records = scan(
        args.library,
        max_total=args.max,
        budget_spec=budget_spec,
        keywords=keywords,
    )
    if args.json:
        _emit_json([asdict(r) for r in records])
    else:
        print(f"library: {args.library}")
        print(f"max: {args.max}  budget: {budget_spec}  keywords: {keywords}")
        print(f"selected: {len(records)} papers\n")
        for r in records:
            kw = (" [" + ",".join(r.matched_keywords) + "]") if r.matched_keywords else ""
            print(f"#{r.priority:>2} [{r.teacher}] score={r.relevance_score:.2f}{kw}")
            print(f"    title: {r.title_from_filename}")
            print(f"    file:  {r.file}\n")
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    root = Path(args.library)
    pdfs = list_pdfs(root)
    if args.json:
        _emit_json([str(p) for p in pdfs])
    else:
        print(f"{len(pdfs)} PDFs under {args.library}:")
        for p in pdfs:
            print(f"  - {p}")
    return 0


def cmd_schema(_: argparse.Namespace) -> int:
    schema = {
        "default_priority_order": list(DEFAULT_PRIORITY_ORDER),
        "default_budget_spec": DEFAULT_BUDGET,
        "record_shape": {
            "priority": "int (1-based, ordered by teacher priority then relevance)",
            "teacher": "str (folder name under library root)",
            "file": "str (PDF path, can be Read directly)",
            "title_from_filename": "str (heuristic extract from 标题_作者.pdf)",
            "relevance_score": "float (0 if no keyword matched; higher = more relevant)",
            "matched_keywords": "list[str] (keywords that hit in the title)",
        },
    }
    _emit_json(schema)
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Scan the local CSPS paper library with priority budgeting, "
                    "dedup, and keyword relevance scoring. Used by "
                    "skills/research-lit Step 0.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("scan", help="Scan and rank papers (main command).")
    sp.add_argument("--library", default="CSPS老师期刊论文收集",
                    help="Path to the local paper library root (default: CSPS老师期刊论文收集)")
    sp.add_argument("--max", type=int, default=20,
                    help="Total max papers to select (default: 20)")
    sp.add_argument("--budget", default=DEFAULT_BUDGET,
                    help='Comma-separated "<folder>:<n>" pairs. '
                         'Unlisted folders split the residual equally. '
                         f'Default: "{DEFAULT_BUDGET}"')
    sp.add_argument("--keywords", default="",
                    help="Whitespace-separated keywords for relevance scoring. "
                         "Empty = no scoring (preserve folder order).")
    sp.add_argument("--json", action="store_true", help="Emit JSON to stdout")
    sp.set_defaults(func=cmd_scan)

    lp = sub.add_parser("list", help="List all PDFs (debug).")
    lp.add_argument("--library", default="CSPS老师期刊论文收集")
    lp.add_argument("--json", action="store_true")
    lp.set_defaults(func=cmd_list)

    dp = sub.add_parser("schema", help="Print default priority order and record shape.")
    dp.set_defaults(func=cmd_schema)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())