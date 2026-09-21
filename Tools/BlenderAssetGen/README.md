# Kingmaker Blender asset generator

`build_kingmaker.py` creates the procedural XR-13 blockout and exports the
runtime USDZ used by `DHPresentation`.

## Generate

Run from the repository root with a Blender installation that supports the
RealityKit/USDZ export path:

```sh
blender --background --factory-startup --python Tools/BlenderAssetGen/build_kingmaker.py
```

An alternate output directory can be supplied after `--`:

```sh
blender --background --factory-startup \
  --python Tools/BlenderAssetGen/build_kingmaker.py -- \
  --output-dir /tmp/kingmaker-generated
```

The script writes the editable `.blend` and intermediate textures under
`Tools/BlenderAssetGen/generated/` (ignored by Git), and writes the runtime
`Kingmaker_XR13.usdz` to `Sources/DHPresentation/Resources/`.

This is a procedural, textured blockout intended to validate the asset
contract and loading path. Final authored meshes, UVs, materials, interiors,
damage variants, animations, and production QA remain art-production work.
