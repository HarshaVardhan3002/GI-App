#!/usr/bin/env python3
"""Generate stand-in images so the app can be built before a dataset exists.

These are not endoscopic images and are not pretending to be. Each one is a
flat card carrying the class name it stands for and the word PLATZHALTER, so
that a screenshot taken during development can never be mistaken for clinical
content. `build_image_bank.py` overwrites them once a real dataset is present.

    python scripts/make_placeholders.py --out ../gi_daily_app
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from build_image_bank import HYPERKVASIR_CLASSES, TARGET_HEIGHT, TARGET_WIDTH

# Classes worth having on hand while building the three question types: a
# landmark, a lesion, and an inflammatory grading — plus the two therapeutic
# views that let one case carry a sequence (lesion, after lifting, margins).
PLACEHOLDER_CLASSES = [
    "normal-z-line",
    "polyp",
    "oesophagitis-a",
    "dyed-lifted-polyps",
    "dyed-resection-margins",
]

# Muted clinical greys. Nothing here should read as a finding.
BACKGROUND = (28, 30, 34)
PANEL = (44, 47, 52)
TEXT = (198, 202, 208)
ACCENT = (176, 122, 60)


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Best available font at `size`, falling back to Pillow's bitmap font."""
    for name in ("segoeui.ttf", "arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_placeholder(class_name: str, destination: Path) -> None:
    image = Image.new("RGB", (TARGET_WIDTH, TARGET_HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)

    margin = 72
    draw.rounded_rectangle(
        (margin, margin, TARGET_WIDTH - margin, TARGET_HEIGHT - margin),
        radius=32,
        fill=PANEL,
    )

    labels = HYPERKVASIR_CLASSES[class_name]

    draw.text(
        (TARGET_WIDTH / 2, TARGET_HEIGHT / 2 - 160),
        "PLATZHALTER",
        font=_font(58),
        fill=ACCENT,
        anchor="mm",
    )
    draw.text(
        (TARGET_WIDTH / 2, TARGET_HEIGHT / 2 - 80),
        "kein endoskopisches Bild",
        font=_font(34),
        fill=TEXT,
        anchor="mm",
    )
    draw.text(
        (TARGET_WIDTH / 2, TARGET_HEIGHT / 2 + 40),
        labels["de"],
        font=_font(46),
        fill=TEXT,
        anchor="mm",
    )
    draw.text(
        (TARGET_WIDTH / 2, TARGET_HEIGHT / 2 + 110),
        class_name,
        font=_font(30),
        fill=(130, 134, 140),
        anchor="mm",
    )

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, "WEBP", quality=82, method=6)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    entries: list[dict[str, object]] = []

    for class_name in PLACEHOLDER_CLASSES:
        image_id = f"placeholder-{class_name}-001"
        asset_path = f"assets/images/{image_id}.webp"
        draw_placeholder(class_name, args.out / asset_path)

        entries.append(
            {
                "id": image_id,
                "source": "placeholder",
                "sourceId": f"generated/{class_name}",
                "className": class_name,
                "assetPath": asset_path,
                "width": TARGET_WIDTH,
                "height": TARGET_HEIGHT,
                "licence": {
                    "spdx": "PLACEHOLDER",
                    "holder": "gi-daily-app Team",
                    "sourceUrl": "https://github.com/",
                    "licenceUrl": "https://github.com/",
                    "attributionText": (
                        "Platzhalter des gi-daily-app Team – "
                        "kein Patientenbild, keine Datensatzquelle"
                    ),
                },
                "addedAt": now,
            }
        )

    out_file = args.out / "assets" / "content" / "images.json"
    out_file.parent.mkdir(parents=True, exist_ok=True)

    existing: list[dict[str, object]] = []
    if out_file.exists():
        existing = json.loads(out_file.read_text(encoding="utf-8"))["images"]
        existing = [
            image for image in existing if image.get("source") != "placeholder"
        ]

    merged = sorted(existing + entries, key=lambda image: str(image["id"]))
    out_file.write_text(
        json.dumps({"version": 1, "images": merged}, ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )

    print(f"Wrote {len(entries)} placeholders ({len(merged)} in bank)")
    print(f"  -> {out_file}")


if __name__ == "__main__":
    main()
