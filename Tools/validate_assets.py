#!/usr/bin/env python3
"""Validate the runtime asset contract without requiring Blender or Xcode."""

from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
USDZ = ROOT / "Sources/DHPresentation/Resources/Kingmaker_XR13.usdz"
REQUIRED = {
    "Kingmaker_XR13.usdc",
    "textures/tex_paint.png",
    "textures/tex_metal.png",
    "textures/tex_rubber.png",
    "textures/tex_dark.png",
}
REQUIRED_ENTITY_LABELS = (b"XR13_Assembly", b"chassis", b"bodyPanels", b"engineBay", b"cabin")
MAX_USDZ_BYTES = 8 * 1024 * 1024
MAX_TEXTURE_BYTES = 2 * 1024 * 1024


def main() -> None:
    if not USDZ.is_file():
        raise SystemExit(f"missing asset: {USDZ}")
    if USDZ.stat().st_size > MAX_USDZ_BYTES:
        raise SystemExit(f"USDZ exceeds {MAX_USDZ_BYTES} byte budget")
    with ZipFile(USDZ) as archive:
        names = set(archive.namelist())
        missing = REQUIRED - names
        if missing:
            raise SystemExit(f"missing USDZ members: {sorted(missing)}")
        bad = archive.testzip()
        if bad:
            raise SystemExit(f"corrupt USDZ member: {bad}")
        for name in names:
            if name.endswith(".png") and archive.getinfo(name).file_size > MAX_TEXTURE_BYTES:
                raise SystemExit(f"texture exceeds {MAX_TEXTURE_BYTES} byte budget: {name}")
        usdc = archive.read("Kingmaker_XR13.usdc")
        missing_labels = [label.decode() for label in REQUIRED_ENTITY_LABELS if label not in usdc]
        if missing_labels:
            raise SystemExit(f"missing stable entity labels: {missing_labels}")
    print(f"validated {USDZ.relative_to(ROOT)} ({USDZ.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
