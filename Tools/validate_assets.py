#!/usr/bin/env python3
"""Validate the runtime asset contract without requiring Blender or Xcode."""

from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
RESOURCE_DIR = ROOT / "Sources/DHPresentation/Resources"
ASSET_CONTRACTS = {
    "Kingmaker_XR13.usdz": {
        "members": {"Kingmaker_XR13.usdc", "textures/tex_paint.png", "textures/tex_metal.png", "textures/tex_rubber.png", "textures/tex_dark.png"},
        # Blender's USD exporter shortens this empty transform label to bodyPan;
        # keep the exported spelling as the stable archive contract.
        "labels": (b"XR13_Assembly", b"chassis", b"bodyPan", b"engineBay", b"cabin"),
    },
    "BlackridgeGarage.usdz": {
        "members": {"BlackridgeGarage.usdc"},
        # Blender 5.x exports the generated door-rib mesh as the compact
        # `door_fr`/`rib__1` pair; validate the stable exported token rather
        # than a pre-export source name.
        "labels": (b"Garage_Assembly", b"lift", b"workbench", b"door_fr", b"Concrete"),
    },
    "BlackridgeRoadSegment.usdz": {
        "members": {"BlackridgeRoadSegment.usdc"},
        "labels": (b"RoadSeg", b"road", b"centerline", b"guardrail"),
    },
}
for _state in ("repaired", "damaged", "rusted"):
    ASSET_CONTRACTS[f"Kingmaker_XR13_{_state}.usdz"] = {
        "members": {f"Kingmaker_XR13_{_state}.usdc"},
        "labels": (b"XR13_Assembly", b"chassis", b"body", b"engineBay", b"cabin"),
    }
MAX_USDZ_BYTES = 8 * 1024 * 1024
MAX_TEXTURE_BYTES = 2 * 1024 * 1024


def check_size_and_textures(usdz: Path) -> None:
    """Budget checks applied to EVERY bundled .usdz, not just the ones with a detailed member/
    label contract below -- so a future asset (interior, terrain, prop, etc.) can't silently blow
    the RealityKit size/texture budget just because nobody wrote it a full ASSET_CONTRACTS entry."""
    if usdz.stat().st_size > MAX_USDZ_BYTES:
        raise SystemExit(f"USDZ exceeds {MAX_USDZ_BYTES} byte budget: {usdz.name}")
    with ZipFile(usdz) as archive:
        bad = archive.testzip()
        if bad:
            raise SystemExit(f"corrupt USDZ member in {usdz.name}: {bad}")
        for name in archive.namelist():
            if name.endswith(".png") and archive.getinfo(name).file_size > MAX_TEXTURE_BYTES:
                raise SystemExit(f"texture exceeds {MAX_TEXTURE_BYTES} byte budget: {usdz.name}:{name}")


def main() -> None:
    for filename, contract in ASSET_CONTRACTS.items():
        usdz = RESOURCE_DIR / filename
        if not usdz.is_file():
            raise SystemExit(f"missing asset: {usdz}")
        check_size_and_textures(usdz)
        with ZipFile(usdz) as archive:
            names = set(archive.namelist())
            missing = contract["members"] - names
            if missing:
                raise SystemExit(f"missing USDZ members in {filename}: {sorted(missing)}")
            usdc = archive.read(next(name for name in names if name.endswith(".usdc")))
            missing_labels = [label.decode() for label in contract["labels"] if label not in usdc]
            if missing_labels:
                raise SystemExit(f"missing stable entity labels in {filename}: {missing_labels}")
        print(f"validated {usdz.relative_to(ROOT)} ({usdz.stat().st_size} bytes)")

    contracted = set(ASSET_CONTRACTS)
    for usdz in sorted(RESOURCE_DIR.glob("*.usdz")):
        if usdz.name in contracted:
            continue
        check_size_and_textures(usdz)
        print(f"validated (budget-only) {usdz.relative_to(ROOT)} ({usdz.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
