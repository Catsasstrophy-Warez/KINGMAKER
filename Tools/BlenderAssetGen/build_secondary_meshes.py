"""Build blockout meshes for the four still-missing mesh/prefab manifest bindings.

Rev10AssetManifest.swift declares kingmaker.enginebay, blackridge.terrain, hostile.vehicle, and
dashboard.warning, but Sources/DHPresentation/Resources/ had no files for any of them --
DHRev10AssetResolver.missingRequiredBindings silently listed all four as missing. Same posture as
the rest of Tools/BlenderAssetGen/: deterministic low-poly blockouts, not final art, generated so
the manifest's contracts actually resolve to something instead of silently failing.
"""
import bpy
import os
import sys

bpy.ops.wm.read_factory_settings(use_empty=True)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
OUT = os.path.join(ROOT, "Sources", "DHPresentation", "Resources")
if "--" in sys.argv:
    args = sys.argv[sys.argv.index("--") + 1:]
    if "--output-dir" in args:
        OUT = os.path.abspath(args[args.index("--output-dir") + 1])
os.makedirs(OUT, exist_ok=True)
GENERATED_DIR = os.path.join(SCRIPT_DIR, "generated")
TEX_DIR = os.path.join(GENERATED_DIR, "textures")

sys.path.insert(0, SCRIPT_DIR)
import proc_textures as pt

PATH_METAL = pt.save_texture(TEX_DIR, "tex_sec_metal", pt.rusted_metal_texture, size=512)
PATH_DIRT = pt.save_texture(TEX_DIR, "tex_sec_dirt", pt.dirt_texture, size=512)
PATH_ASPHALT = pt.save_texture(TEX_DIR, "tex_sec_asphalt", pt.asphalt_texture, size=256)


def mat(name, color, metallic=0.0, roughness=0.6, texture_path=None):
    return pt.make_material(name, color, metallic=metallic, roughness=roughness, texture_path=texture_path)


def with_bevel(obj, width=0.015, segments=2):
    mod = obj.modifiers.new("EdgeBevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    return obj


def cube(name, size, location, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    return o


def cylinder(name, radius, depth, location, material, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location, rotation=rotation)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    return o


def export(name, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.select_set(True)
    path = os.path.join(OUT, name)
    bpy.ops.wm.usd_export(
        filepath=path,
        selected_objects_only=True,
        export_materials=True,
        export_meshes=True,
        export_uvmaps=True,
        export_normals=True,
    )
    print("EXPORTED", path, os.path.exists(path) and os.path.getsize(path))
    for o in objects:
        bpy.data.objects.remove(o, do_unlink=True)


ENGINE_METAL = mat("EngineBay_Metal", (0.22, 0.22, 0.24), metallic=0.7, roughness=0.4, texture_path=PATH_METAL)
ENGINE_BLOCK = mat("EngineBay_Block", (0.12, 0.12, 0.13), metallic=0.3, roughness=0.5, texture_path=PATH_METAL)

engine_objs = [
    cube("engine_bay_frame", (1.3, 1.0, 0.05), (0, 0, 0), ENGINE_METAL),
    cube("engine_block", (0.7, 0.55, 0.5), (0, 0, 0.28), ENGINE_BLOCK),
    cylinder("radiator", 0.32, 0.12, (0, -0.55, 0.35), ENGINE_METAL, rotation=(1.5708, 0, 0)),
    cube("intake_manifold", (0.35, 0.2, 0.15), (0, 0.1, 0.58), ENGINE_METAL),
    cylinder("air_filter", 0.14, 0.18, (0.3, 0.1, 0.65), ENGINE_METAL),
]
export("Kingmaker_EngineBay.usdz", engine_objs)

TERRAIN_DIRT = mat("Terrain_Dirt", (0.32, 0.24, 0.16), roughness=0.9, texture_path=PATH_DIRT)
TERRAIN_ROAD = mat("Terrain_Road", (0.1, 0.1, 0.1), roughness=0.8, texture_path=PATH_ASPHALT)

terrain_objs = [
    cube("terrain_ground", (60, 60, 1), (0, 0, -0.5), TERRAIN_DIRT),
    cube("terrain_ridge_a", (14, 6, 2.5), (-16, 10, 0.75), TERRAIN_DIRT),
    cube("terrain_ridge_b", (10, 8, 1.8), (18, -14, 0.4), TERRAIN_DIRT),
    cube("terrain_road_strip", (4, 60, 0.06), (0, 0, 0.03), TERRAIN_ROAD),
]
export("BlackridgeCounty_Terrain.usdz", terrain_objs)

RAIDER_BODY = mat("Raider_Body", (0.28, 0.05, 0.03), roughness=0.7, texture_path=PATH_METAL)
RAIDER_ARMOR = mat("Raider_Armor", (0.15, 0.15, 0.15), metallic=0.5, roughness=0.6, texture_path=PATH_METAL)
RAIDER_TIRE = mat("Raider_Tire", (0.02, 0.02, 0.02), roughness=1.0)

raider_objs = [
    with_bevel(cube("raider_chassis", (4.6, 1.9, 0.5), (0, 0, 0.55), RAIDER_BODY)),
    with_bevel(cube("raider_cabin", (2.0, 1.7, 0.7), (0.3, 0, 1.05), RAIDER_BODY)),
    cube("raider_ram_bar", (0.3, 2.1, 0.6), (2.4, 0, 0.7), RAIDER_ARMOR),
    cube("raider_armor_plate_L", (2.6, 0.15, 0.9), (0, 1.0, 0.75), RAIDER_ARMOR),
    cube("raider_armor_plate_R", (2.6, 0.15, 0.9), (0, -1.0, 0.75), RAIDER_ARMOR),
]
for x, y in [(1.4, 0.95), (1.4, -0.95), (-1.4, 0.95), (-1.4, -0.95)]:
    raider_objs.append(cylinder(f"raider_wheel_{x}_{y}", 0.42, 0.32, (x, y, 0.42), RAIDER_TIRE, rotation=(1.5708, 0, 0)))
export("HostileVehicle_Raider.usdz", raider_objs)

DASH_PLASTIC = mat("Dashboard_Plastic", (0.05, 0.05, 0.06), roughness=0.5)
DASH_WARN = mat("Dashboard_Warning", (0.9, 0.15, 0.05), roughness=0.3)
DASH_GAUGE = mat("Dashboard_Gauge", (0.02, 0.02, 0.02), roughness=0.2)

dash_objs = [
    with_bevel(cube("dashboard_panel", (1.1, 0.08, 0.3), (0, 0, 0), DASH_PLASTIC), width=0.01, segments=2),
    cylinder("gauge_speedo", 0.09, 0.02, (-0.25, -0.05, 0.05), DASH_GAUGE, rotation=(1.5708, 0, 0)),
    cylinder("gauge_tach", 0.09, 0.02, (0.25, -0.05, 0.05), DASH_GAUGE, rotation=(1.5708, 0, 0)),
    cube("warning_light_oil", (0.06, 0.02, 0.06), (-0.05, -0.05, 0.14), DASH_WARN),
    cube("warning_light_temp", (0.06, 0.02, 0.06), (0.05, -0.05, 0.14), DASH_WARN),
]
export("XR13_Dashboard.usdz", dash_objs)
