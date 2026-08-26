#!/usr/bin/env python3
"""Turn a downloaded dataset into the app's image bank.

Reads a HyperKvasir or GastroVision directory, converts each selected image to
a 4:5 WebP sized for a phone, and writes `images.json` next to the app's other
content.

    python scripts/build_image_bank.py \
        --dataset hyperkvasir \
        --source  D:/datasets/hyperkvasir/labeled-images \
        --out     ../gi_daily_app \
        --per-class 3

Two things this script refuses to do:

* It will not invent a class name. Dataset folder names are the labels, and
  they are unintuitive on purpose. If it meets a folder that is not in
  HYPERKVASIR_CLASSES it stops and tells you to add it, rather than guessing a
  German label for something it does not recognise.
* It will not write an image without a licence block. Constraint 1 of this
  project is that nothing reaches a user unattributed.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - environment problem, not logic
    sys.exit("Pillow is required: pip install Pillow")


# ---------------------------------------------------------------------------
# Canonical class names
# ---------------------------------------------------------------------------

# The dataset's folder names, mapped to the labels we show a physician.
#
# IMPORT THIS. Do not retype these strings anywhere else in the project: they
# are irregular (`normal-z-line` not `z-line`, `oesophagitis-a` in British
# spelling, `polyp` singular), and a typo produces an image bank that validates
# fine and labels the wrong thing.
#
# `de` is what the app renders. `en` exists so an English-speaking developer can
# read the bank while working; it is never shown outside the debug locale.
HYPERKVASIR_CLASSES: dict[str, dict[str, str]] = {
    # Anatomical landmarks
    "normal-z-line": {"de": "Z-Linie, unauffällig", "en": "Z-line, normal"},
    "normal-pylorus": {"de": "Pylorus, unauffällig", "en": "Pylorus, normal"},
    "normal-cecum": {"de": "Zökum, unauffällig", "en": "Cecum, normal"},
    "ileum": {"de": "Terminales Ileum", "en": "Terminal ileum"},
    "retroflex-stomach": {
        "de": "Magen in Retroflexion",
        "en": "Stomach, retroflex view",
    },
    "retroflex-rectum": {
        "de": "Rektum in Retroflexion",
        "en": "Rectum, retroflex view",
    },
    # Pathological findings
    "polyp": {"de": "Polyp", "en": "Polyp"},
    "oesophagitis-a": {
        "de": "Refluxösophagitis Los-Angeles-Grad A",
        "en": "Reflux oesophagitis, LA grade A",
    },
    "oesophagitis-b-d": {
        "de": "Refluxösophagitis Los-Angeles-Grad B–D",
        "en": "Reflux oesophagitis, LA grade B–D",
    },
    "barretts": {"de": "Barrett-Ösophagus", "en": "Barrett's oesophagus"},
    "barretts-short-segment": {
        "de": "Barrett-Ösophagus, Short-Segment",
        "en": "Barrett's oesophagus, short segment",
    },
    "haemorrhoids": {"de": "Hämorrhoiden", "en": "Haemorrhoids"},
    "ulcerative-colitis-grade-0-1": {
        "de": "Colitis ulcerosa, Mayo 0–1",
        "en": "Ulcerative colitis, Mayo 0–1",
    },
    "ulcerative-colitis-grade-1": {
        "de": "Colitis ulcerosa, Mayo 1",
        "en": "Ulcerative colitis, Mayo 1",
    },
    "ulcerative-colitis-grade-1-2": {
        "de": "Colitis ulcerosa, Mayo 1–2",
        "en": "Ulcerative colitis, Mayo 1–2",
    },
    "ulcerative-colitis-grade-2": {
        "de": "Colitis ulcerosa, Mayo 2",
        "en": "Ulcerative colitis, Mayo 2",
    },
    "ulcerative-colitis-grade-2-3": {
        "de": "Colitis ulcerosa, Mayo 2–3",
        "en": "Ulcerative colitis, Mayo 2–3",
    },
    "ulcerative-colitis-grade-3": {
        "de": "Colitis ulcerosa, Mayo 3",
        "en": "Ulcerative colitis, Mayo 3",
    },
    # Therapeutic interventions
    "dyed-lifted-polyps": {
        "de": "Polyp nach Unterspritzung, angefärbt",
        "en": "Dyed, lifted polyp",
    },
    "dyed-resection-margins": {
        "de": "Angefärbte Resektionsränder",
        "en": "Dyed resection margins",
    },
    # Quality of mucosal views
    "bbps-0-1": {
        "de": "Darmvorbereitung BBPS 0–1",
        "en": "Bowel prep, BBPS 0–1",
    },
    "bbps-2-3": {
        "de": "Darmvorbereitung BBPS 2–3",
        "en": "Bowel prep, BBPS 2–3",
    },
    "impacted-stool": {"de": "Stuhlreste", "en": "Impacted stool"},
}

# GastroVision uses its own vocabulary. Kept separate so the two are never
# silently merged; a class present in both datasets can still mean two things.
GASTROVISION_CLASSES: dict[str, dict[str, str]] = {
    "normal-mucosa-and-vascular-pattern-in-the-large-bowel": {
        "de": "Kolonmukosa mit regelrechtem Gefäßmuster",
        "en": "Normal large-bowel mucosa and vascular pattern",
    },
    "colon-polyps": {"de": "Kolonpolypen", "en": "Colon polyps"},
    "gastric-polyps": {"de": "Magenpolypen", "en": "Gastric polyps"},
    "oesophagitis": {"de": "Ösophagitis", "en": "Oesophagitis"},
    "barretts-mucosa": {"de": "Barrett-Mukosa", "en": "Barrett's mucosa"},
    "duodenal-bulb": {"de": "Bulbus duodeni", "en": "Duodenal bulb"},
    "normal-stomach": {"de": "Magen, unauffällig", "en": "Normal stomach"},
    "ulcer": {"de": "Ulkus", "en": "Ulcer"},
}

CLASS_MAPS = {
    "hyperkvasir": HYPERKVASIR_CLASSES,
    "gastrovision": GASTROVISION_CLASSES,
}


# ---------------------------------------------------------------------------
# Licensing
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class DatasetLicence:
    """Everything needed to attribute one dataset on screen."""

    holder: str
    source_url: str
    attribution: str

    def as_json(self) -> dict[str, str]:
        return {
            "spdx": "CC-BY-4.0",
            "holder": self.holder,
            "sourceUrl": self.source_url,
            "licenceUrl": "https://creativecommons.org/licenses/by/4.0/",
            "attributionText": self.attribution,
        }


LICENCES: dict[str, DatasetLicence] = {
    "hyperkvasir": DatasetLicence(
        holder="Borgli et al., HyperKvasir",
        source_url="https://datasets.simula.no/hyper-kvasir/",
        attribution=(
            "Bild: Borgli et al., HyperKvasir (Simula), CC BY 4.0"
        ),
    ),
    "gastrovision": DatasetLicence(
        holder="Jha et al., GastroVision",
        source_url="https://github.com/DebeshJha/GastroVision",
        attribution="Bild: Jha et al., GastroVision, CC BY 4.0",
    ),
}


# ---------------------------------------------------------------------------
# Image conversion
# ---------------------------------------------------------------------------

# 4:5 portrait, the Instagram post ratio. Height is derived, not configured, so
# every image in the bank crops identically and the feed never jumps.
TARGET_WIDTH = 1080
TARGET_HEIGHT = 1350
WEBP_QUALITY = 82

SUPPORTED_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"}


def to_four_by_five(source: Path, destination: Path) -> tuple[int, int]:
    """Centre-crop `source` to 4:5 and write it as WebP. Returns (w, h).

    Endoscopic images are usually wider than 4:5 and carry black borders and a
    scope overlay at the edges. A centre crop keeps the lumen, which is what the
    question is about; anything cleverer belongs in a classifier, not here.
    """
    with Image.open(source) as image:
        image = image.convert("RGB")
        width, height = image.size

        target_ratio = TARGET_WIDTH / TARGET_HEIGHT
        source_ratio = width / height

        if source_ratio > target_ratio:
            # Too wide: trim the sides.
            new_width = round(height * target_ratio)
            offset = (width - new_width) // 2
            box = (offset, 0, offset + new_width, height)
        else:
            # Too tall: trim top and bottom.
            new_height = round(width / target_ratio)
            offset = (height - new_height) // 2
            box = (0, offset, width, offset + new_height)

        cropped = image.crop(box).resize(
            (TARGET_WIDTH, TARGET_HEIGHT), Image.LANCZOS
        )
        destination.parent.mkdir(parents=True, exist_ok=True)
        cropped.save(destination, "WEBP", quality=WEBP_QUALITY, method=6)

    return TARGET_WIDTH, TARGET_HEIGHT


# ---------------------------------------------------------------------------
# Building the bank
# ---------------------------------------------------------------------------


def find_class_dirs(root: Path) -> dict[str, list[Path]]:
    """Map class name to its image files.

    HyperKvasir nests classes under anatomical groupings
    (`upper-gi-tract/pathological-findings/polyp`), so the class is taken from
    the deepest directory that actually holds images, at whatever depth.
    """
    by_class: dict[str, list[Path]] = {}

    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED_SUFFIXES:
            continue
        class_name = path.parent.name
        by_class.setdefault(class_name, []).append(path)

    return by_class


def build(
    dataset: str,
    source_root: Path,
    app_root: Path,
    per_class: int,
) -> int:
    class_map = CLASS_MAPS[dataset]
    licence = LICENCES[dataset]

    by_class = find_class_dirs(source_root)
    if not by_class:
        sys.exit(f"No images found under {source_root}")

    unknown = sorted(set(by_class) - set(class_map))
    if unknown:
        listed = "\n  ".join(unknown)
        sys.exit(
            "Unknown class folders. Add them to the class map in this file "
            "with a German label, then rerun:\n  " + listed
        )

    images: list[dict[str, object]] = []
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")

    for class_name in sorted(by_class):
        files = by_class[class_name][:per_class]
        for index, source_file in enumerate(files, start=1):
            image_id = f"{dataset}-{class_name}-{index:03d}"
            asset_path = f"assets/images/{image_id}.webp"
            width, height = to_four_by_five(
                source_file, app_root / asset_path
            )

            images.append(
                {
                    "id": image_id,
                    "source": dataset,
                    "sourceId": source_file.name,
                    "className": class_name,
                    "assetPath": asset_path,
                    "width": width,
                    "height": height,
                    "licence": licence.as_json(),
                    "addedAt": now,
                }
            )

    out_file = app_root / "assets" / "content" / "images.json"
    out_file.parent.mkdir(parents=True, exist_ok=True)

    # Merge with whatever is already there: a run over GastroVision must not
    # wipe the HyperKvasir entries.
    existing: list[dict[str, object]] = []
    if out_file.exists():
        existing = json.loads(out_file.read_text(encoding="utf-8"))["images"]
        existing = [
            image for image in existing if image.get("source") != dataset
        ]

    merged = sorted(existing + images, key=lambda image: str(image["id"]))
    out_file.write_text(
        json.dumps({"version": 1, "images": merged}, ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )

    print(f"Wrote {len(images)} {dataset} images ({len(merged)} in bank)")
    print(f"  -> {out_file}")
    return len(images)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dataset", required=True, choices=sorted(CLASS_MAPS)
    )
    parser.add_argument(
        "--source", required=True, type=Path, help="dataset directory"
    )
    parser.add_argument(
        "--out",
        required=True,
        type=Path,
        help="Flutter app root (the directory holding assets/)",
    )
    parser.add_argument(
        "--per-class",
        type=int,
        default=3,
        help="how many images to take from each class",
    )
    args = parser.parse_args()

    if not args.source.is_dir():
        sys.exit(f"Not a directory: {args.source}")

    build(args.dataset, args.source, args.out, args.per_class)


if __name__ == "__main__":
    main()
