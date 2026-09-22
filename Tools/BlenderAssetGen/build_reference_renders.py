"""Render a committed reference screenshot for every bundled asset -- a visual regression
baseline. Previously there was no way to eyeball "did this asset visibly change" without manually
opening each USDZ; this renders each into Tools/BlenderAssetGen/reference_renders/ (tracked, not
generated/ which is gitignored) so a diff of that directory shows what actually changed visually
across a regeneration pass. Not pixel-diffed automatically (lighting/AA noise would make an exact
comparison brittle) -- it's a human-reviewable baseline, similar in spirit to how
Tools/validate_assets.py checks structural properties (size, member presence) rather than pixels.

Reuses the render_asset() camera/lighting approach from the existing (untracked, /tmp-output)
render_previews.py scratch tool, but writes into a committed directory and covers every asset
currently bundled, not just the vehicle/garage/road three.
"""
import bpy
import os
import sys
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
RESOURCE = os.path.join(ROOT, "Sources", "DHPresentation", "Resources")
OUT = os.path.join(os.path.dirname(__file__), "reference_renders")
if "--" in sys.argv:
    args = sys.argv[sys.argv.index("--") + 1:]
    if "--output-dir" in args:
        OUT = os.path.abspath(args[args.index("--output-dir") + 1])
os.makedirs(OUT, exist_ok=True)


def look_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_asset(filename, output, camera_location, target, scale=1.0):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path = os.path.join(RESOURCE, filename)
    if not os.path.exists(path):
        print("SKIP (missing)", filename)
        return
    bpy.ops.wm.usd_import(filepath=path)
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for obj in objects:
        obj.scale *= scale
    bpy.ops.object.light_add(type="AREA", location=(4, -5, 8))
    key = bpy.context.object
    key.data.energy = 1300
    key.data.shape = "DISK"
    key.data.size = 5
    look_at(key, (0, 0, 0))
    bpy.ops.object.light_add(type="AREA", location=(-5, 4, 4))
    fill = bpy.context.object
    fill.data.energy = 700
    fill.data.size = 4
    look_at(fill, (0, 0, 0))
    bpy.ops.object.camera_add(location=camera_location)
    camera = bpy.context.object
    look_at(camera, target)
    camera.data.lens = 52
    bpy.context.scene.camera = camera
    world = bpy.context.scene.world or bpy.data.worlds.new("PreviewWorld")
    bpy.context.scene.world = world
    world.color = (0.008, 0.01, 0.014)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 480
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(OUT, output)
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    print("WROTE", os.path.join(OUT, output))


ASSETS = [
    ("Kingmaker_XR13.usdz", "kingmaker.png", (7.5, -7.5, 4.5), (0, 0, 0.7), 1.0),
    ("Kingmaker_EngineBay.usdz", "kingmaker_enginebay.png", (2.2, -2.2, 1.4), (0, 0, 0.3), 1.0),
    ("XR13_Dashboard.usdz", "kingmaker_dashboard.png", (1.0, -1.4, 0.6), (0, 0, 0), 1.0),
    ("HostileVehicle_Raider.usdz", "hostile_raider.png", (6.5, -6.5, 3.8), (0, 0, 0.6), 1.0),
    ("BlackridgeGarage.usdz", "garage.png", (15, -17, 11), (0, 0, 2), 1.0),
    ("BlackridgeRoadSegment.usdz", "road.png", (15, -16, 9), (0, 0, 0), 1.0),
    ("BlackridgeCounty_Terrain.usdz", "terrain.png", (30, -30, 20), (0, 0, 0), 1.0),
    ("ParadiseInterior.usdz", "paradise_interior.png", (10, -10, 6), (0, 0, 1.8), 1.0),
    ("TruckStopInterior.usdz", "truckstop_interior.png", (8, -8, 5), (0, 0, 1.6), 1.0),
    ("Mannequin_WalkCycle.usdz", "mannequin.png", (2.2, -2.2, 1.4), (0, 0, 0.9), 1.0),
]

for filename, output, cam, target, scale in ASSETS:
    render_asset(filename, output, cam, target, scale)

print("DONE", OUT)
