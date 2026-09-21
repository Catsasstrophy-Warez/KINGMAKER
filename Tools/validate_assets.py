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


def main() -> None:
    if not USDZ.is_file():
        raise SystemExit(f"missing asset: {USDZ}")
    with ZipFile(USDZ) as archive:
        names = set(archive.namelist())
        missing = REQUIRED - names
        if missing:
            raise SystemExit(f"missing USDZ members: {sorted(missing)}")
        bad = archive.testzip()
        if bad:
            raise SystemExit(f"corrupt USDZ member: {bad}")
    print(f"validated {USDZ.relative_to(ROOT)} ({USDZ.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
