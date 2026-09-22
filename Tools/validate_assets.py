#!/usr/bin/env python3
"""Validate the runtime asset contract without requiring Blender or Xcode."""

import json
from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
RESOURCE_DIR = ROOT / "Sources/DHPresentation/Resources"
ASSET_CONTRACTS = {
    "Kingmaker_XR13.usdz": {
        "members": {"Kingmaker_XR13.usdc", "textures/tex_paint.png", "textures/tex_metal.png", "textures/tex_rubber.png", "textures/tex_dark.png"},
        # Raw USDC string tables retain the assembly/chassis/engine-bay anchors;
        # decoded hierarchy labels are checked separately by production_qa.py.
        #
        # The 10 deform_<zone> blend-shape target names (Tools/BlenderAssetGen/build_kingmaker.py)
        # are deliberately NOT checked here: USD's crate format compresses the token section they
        # land in, so a raw byte search never finds them even though they're genuinely present --
        # confirmed instead via `pxr.UsdSkel` stage introspection at build time (requires
        # Blender's bundled Python, which this script's docstring explicitly avoids depending on).
        "labels": (b"XR13_Assembly", b"chassis", b"engineBay"),
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
        "labels": (b"XR13_Assembly", b"chassis", b"engineBay"),
    }
MAX_USDZ_BYTES = 8 * 1024 * 1024
MAX_TEXTURE_BYTES = 2 * 1024 * 1024
JSON_CONTRACTS = {
    "BlackridgeGarage.navmesh": ("chunkID", "polygons"),
    "Player_Repair.anim": ("name", "fps", "durationSeconds", "frameCount", "tracks"),
    "Kingmaker_Start.anim": ("name", "fps", "durationSeconds", "frameCount", "tracks"),
}


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
    for filename, keys in JSON_CONTRACTS.items():
        path = RESOURCE_DIR / filename
        if not path.is_file():
            raise SystemExit(f"missing data asset: {path}")
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise SystemExit(f"invalid JSON data asset {filename}: {error}") from error
        missing_keys = [key for key in keys if key not in payload]
        if missing_keys:
            raise SystemExit(f"missing data keys in {filename}: {missing_keys}")
        if filename.endswith(".anim"):
            if payload["fps"] <= 0 or payload["durationSeconds"] <= 0 or payload["frameCount"] < 2:
                raise SystemExit(f"invalid animation timing in {filename}")
            tracks = payload["tracks"]
            if not isinstance(tracks, list) or not tracks:
                raise SystemExit(f"animation has no tracks: {filename}")
            for track in tracks:
                if not track.get("bone") or track.get("axis") not in {"x", "y", "z"}:
                    raise SystemExit(f"invalid animation track identity in {filename}: {track}")
                if len(track.get("keyframes", [])) < 2:
                    raise SystemExit(f"animation track has too few keyframes in {filename}: {track}")
        print(f"validated {path.relative_to(ROOT)} ({path.stat().st_size} bytes)")

    usda = RESOURCE_DIR / "VehicleCombat_FX.usda"
    if not usda.is_file() or not usda.read_text(encoding="utf-8").startswith("#usda"):
        raise SystemExit(f"invalid particle asset: {usda}")
    print(f"validated {usda.relative_to(ROOT)} ({usda.stat().st_size} bytes)")

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
