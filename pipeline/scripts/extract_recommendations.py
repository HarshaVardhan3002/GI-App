#!/usr/bin/env python3
"""Pull numbered recommendations out of an AWMF guideline PDF.

    python scripts/extract_recommendations.py \
        --pdf       D:/leitlinien/021-007OL.pdf \
        --guideline dgvs-s3-kolorektales-karzinom \
        --out       ../gi_daily_app/assets/content/recommendations.json

What this produces is a starting point, not a result. AWMF guidelines are typeset
documents, not data: recommendation blocks are laid out in tables, split across
page breaks, and worded slightly differently between guidelines. This script
finds the blocks it can and reports what it could not, and every entry it writes
is expected to be read by a person before it is used.

Two behaviours are deliberate:

* Quotes are truncated to QUOTE_MAX_CHARS. We cite, we do not redistribute, and
  a script that quietly emitted three paragraphs would break that on our behalf.
* Nothing is overwritten. Recommendations already in the output file are kept
  as they are, because they may have been corrected by hand since extraction.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    import pdfplumber
except ImportError:  # pragma: no cover - environment problem, not logic
    sys.exit("pdfplumber is required: pip install pdfplumber")


# Kept in step with QUOTE_MAX_CHARS in pipeline/src/lib/schema.ts.
QUOTE_MAX_CHARS = 400

# "Empfehlung 6.12", "Empfehlung 6.12:", "Statement 3.4", "Konsensbasierte
# Empfehlung 2.1" — the number is what we key on, the label varies.
RECOMMENDATION_HEAD = re.compile(
    r"(?:Konsensbasierte[s]?\s+|Evidenzbasierte[s]?\s+)?"
    r"(?:Empfehlung|Statement|Empfehlungen)\s+"
    r"(?P<number>\d+(?:\.\d+)+)\s*:?",
    re.IGNORECASE,
)

# "Empfehlungsgrad A", "Empfehlungsgrad: B", "EG 0", or a bare "EK" for an
# Expertenkonsens with no graded evidence behind it.
STRENGTH = re.compile(
    r"(?:Empfehlungsgrad|EG)\s*:?\s*(?P<grade>[AB0])\b|\b(?P<ek>EK)\b",
)

CONSENSUS = re.compile(
    r"(starker Konsens|Konsens|mehrheitliche Zustimmung|kein Konsens)",
)

LEVEL_OF_EVIDENCE = re.compile(
    r"(?:Level of Evidence|LoE|Evidenzgrad)\s*:?\s*(?P<loe>[0-9]+[a-d]?)",
    re.IGNORECASE,
)


@dataclass
class Extracted:
    """One recommendation as found in the PDF, before a human looks at it."""

    number: str
    page: int
    body: str
    strength: str | None = None
    consensus: str | None = None
    level_of_evidence: str | None = None
    problems: list[str] = field(default_factory=list)

    def quote(self) -> str:
        """The body, collapsed to one line and cut to the licence limit."""
        text = " ".join(self.body.split())
        if len(text) <= QUOTE_MAX_CHARS:
            return text
        # Cut at a word boundary so the ellipsis does not land mid-word.
        cut = text[: QUOTE_MAX_CHARS - 1].rsplit(" ", 1)[0]
        return f"{cut}…"


def extract(pdf_path: Path) -> list[Extracted]:
    """Walk the PDF and return every recommendation block it can identify."""
    found: list[Extracted] = []

    with pdfplumber.open(pdf_path) as pdf:
        for page_number, page in enumerate(pdf.pages, start=1):
            text = page.extract_text() or ""
            if not text:
                continue

            heads = list(RECOMMENDATION_HEAD.finditer(text))
            for index, head in enumerate(heads):
                start = head.end()
                end = (
                    heads[index + 1].start()
                    if index + 1 < len(heads)
                    else len(text)
                )
                block = text[start:end].strip()

                entry = Extracted(
                    number=head.group("number"),
                    page=page_number,
                    body=block,
                )

                strength_match = STRENGTH.search(block)
                if strength_match:
                    entry.strength = (
                        strength_match.group("grade")
                        or strength_match.group("ek")
                    )
                else:
                    entry.problems.append("no Empfehlungsgrad found")

                consensus_match = CONSENSUS.search(block)
                if consensus_match:
                    entry.consensus = consensus_match.group(1)

                loe_match = LEVEL_OF_EVIDENCE.search(block)
                if loe_match:
                    entry.level_of_evidence = f"LoE {loe_match.group('loe')}"

                if len(entry.body) < 40:
                    # Almost certainly a cross-reference in running text rather
                    # than the recommendation itself.
                    entry.problems.append("body too short, likely a reference")

                if len(" ".join(entry.body.split())) > QUOTE_MAX_CHARS:
                    entry.problems.append(
                        "body exceeds the quote limit and was truncated — "
                        "check the cut reads as a citation"
                    )

                found.append(entry)

    return found


def to_json(
    entry: Extracted,
    guideline_id: str,
    citation_template: str,
) -> dict[str, object]:
    record: dict[str, object] = {
        "id": f"{guideline_id}-r-{entry.number}",
        "guidelineId": guideline_id,
        "number": entry.number,
        # Falls back to EK rather than guessing a grade the document did not
        # state. A wrong Empfehlungsgrad is worse than an unspecific one.
        "strength": entry.strength or "EK",
        "quote": entry.quote(),
        "citation": citation_template.format(number=entry.number),
        "page": entry.page,
    }
    if entry.consensus:
        record["consensus"] = entry.consensus
    if entry.level_of_evidence:
        record["levelOfEvidence"] = entry.level_of_evidence
    return record


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument(
        "--guideline",
        required=True,
        help="guideline id, must already exist in guidelines.json",
    )
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument(
        "--citation",
        default="{guideline}, Empfehlung {number}",
        help="citation line; {number} is substituted per recommendation",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report what was found without writing anything",
    )
    args = parser.parse_args()

    if not args.pdf.is_file():
        sys.exit(f"Not a file: {args.pdf}")

    entries = extract(args.pdf)
    if not entries:
        sys.exit(
            "No recommendations found. The heading pattern in this guideline "
            "differs from the ones handled here — check RECOMMENDATION_HEAD."
        )

    citation_template = args.citation.replace("{guideline}", args.guideline)
    records = [to_json(entry, args.guideline, citation_template) for entry in entries]

    flagged = [entry for entry in entries if entry.problems]
    print(f"Found {len(entries)} recommendations in {args.pdf.name}")
    if flagged:
        print(f"{len(flagged)} need a human read:")
        for entry in flagged:
            print(f"  {entry.number} (p{entry.page}): {'; '.join(entry.problems)}")

    if args.dry_run:
        print("\nDry run, nothing written.")
        return

    existing: list[dict[str, object]] = []
    if args.out.exists():
        existing = json.loads(args.out.read_text(encoding="utf-8"))[
            "recommendations"
        ]

    # Anything already present wins: it may have been corrected by hand.
    known = {str(record["id"]) for record in existing}
    added = [record for record in records if record["id"] not in known]

    merged = sorted(existing + added, key=lambda record: str(record["id"]))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(
            {"version": 1, "recommendations": merged},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"\nAdded {len(added)} new, kept {len(existing)} existing")
    print(f"  -> {args.out}")
    print("Review every added entry before any of it is shown to a user.")


if __name__ == "__main__":
    main()
