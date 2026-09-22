"""Build the authored-looking Rev10 garage and first road segment blockout.

This intentionally stays deterministic and low-poly so it can be regenerated in CI.
It is a replaceable environment asset, not a claim of final art.
"""
import bpy
import math
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

def mat(name, color, metallic=0.0, roughness=0.65, emission=None):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color, 1)
    m.use_nodes = True; bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic; bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1); bsdf.inputs["Emission Strength"].default_value = 2.0
    return m

CONCRETE = mat("Garage_Concrete", (0.12, 0.13, 0.14), roughness=0.9)
STEEL = mat("Garage_Steel", (0.25, 0.28, 0.30), metallic=0.8, roughness=0.35)
RUST = mat("Garage_RustedSteel", (0.22, 0.08, 0.035), metallic=0.45, roughness=0.7)
YELLOW = mat("Safety_Yellow", (0.85, 0.46, 0.03), roughness=0.45)
ROAD = mat("Road_Asphalt", (0.035, 0.04, 0.045), roughness=0.95)
LINE = mat("Road_Marking", (0.82, 0.68, 0.27), roughness=0.55)
NEON = mat("Guide_Light", (0.03, 0.15, 0.18), emission=(0.02, 0.5, 0.65))

def cube(name, size, location, material, parent=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    o = bpy.context.object; o.name = name; o.dimensions = size; bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    if parent: o.parent = parent
    if bevel:
        mod = o.modifiers.new("EdgeBevel", "BEVEL"); mod.width = bevel; mod.segments = 2
    return o

def cylinder(name, radius, depth, location, material, rotation=(0, 0, 0), vertices=20, parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    o = bpy.context.object; o.name = name; o.data.materials.append(material)
    if parent: o.parent = parent
    for p in o.data.polygons: p.use_smooth = True
    return o

def empty(name):
    e = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(e); return e

def garage():
    root = empty("BlackridgeGarage_Assembly")
    cube("garage_floor", (18, 14, 0.18), (0, 0, -0.09), CONCRETE, root)
    cube("garage_back_wall", (18, 0.25, 5.5), (0, 6.8, 2.75), CONCRETE, root)
    cube("garage_left_wall", (0.25, 14, 5.5), (-9, 0, 2.75), CONCRETE, root)
    cube("garage_right_wall", (0.25, 14, 5.5), (9, 0, 2.75), CONCRETE, root)
    cube("garage_beam_front", (18, 0.3, 0.35), (0, -6.5, 5.2), STEEL, root)
    cube("garage_lift_pad", (5.2, 3.2, 0.16), (0, 0, 0.08), STEEL, root, 0.08)
    for x in (-2.15, 2.15):
        cube("lift_post_" + str(x), (0.22, 0.22, 2.5), (x, 0, 1.3), STEEL, root, 0.03)
        cube("lift_arm_" + str(x), (1.15, 0.12, 0.12), (x * 0.55, 0, 1.4), YELLOW, root, 0.02)
    cube("workbench", (4.6, 0.8, 1.1), (5.8, 3.7, 0.55), RUST, root, 0.05)
    cube("toolwall", (4.8, 0.16, 2.6), (5.8, 4.2, 2.0), STEEL, root)
    for i in range(8):
        cylinder("tool_hook_%02d" % i, 0.035, 0.45, (4.0 + (i % 4) * 0.6, 4.05, 1.3 + (i // 4) * 0.5), YELLOW, rotation=(math.pi / 2, 0, 0), vertices=12, parent=root)
    for x in (-6.5, 6.5):
        cylinder("warning_beacon_%s" % x, 0.18, 0.12, (x, 5.9, 4.7), NEON, vertices=20, parent=root)
    cube("garage_door_frame", (7.0, 0.18, 4.2), (0, -6.65, 2.1), STEEL, root, 0.05)
    for x in range(-3, 4): cube("door_rib_%s" % x, (0.07, 0.25, 3.8), (x, -6.48, 2.1), RUST, root)
    return root

def road():
    root = empty("BlackridgeRoadSegment_Assembly")
    cube("road_surface", (28, 8, 0.18), (0, 0, -0.09), ROAD, root)
    for x in range(-12, 13, 4):
        cube("centerline_%s" % x, (1.8, 0.12, 0.025), (x, 0, 0.02), LINE, root)
    for y in (-3.7, 3.7):
        cube("edge_line_%s" % y, (28, 0.09, 0.025), (0, y, 0.02), LINE, root)
        for x in (-11, -5, 1, 7, 13):
            cylinder("road_marker_%s_%s" % (x, y), 0.08, 0.8, (x, y, 0.23), YELLOW, vertices=12, parent=root)
    for x in (-10, 0, 10):
        cylinder("guardrail_post_%s" % x, 0.06, 1.2, (x, 4.8, 0.6), STEEL, vertices=12, parent=root)
        cube("guardrail_%s" % x, (9.0, 0.08, 0.12), (x, 4.8, 1.05), STEEL, root, 0.03)
    return root

garage_root = garage(); road_root = road()
for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        bpy.ops.object.shade_smooth_by_angle()
        o.select_set(False)

def members(root):
    return [o for o in bpy.context.scene.objects if o == root or o.parent == root or (o.parent and o.parent.parent == root)]

def export(root, name):
    path = os.path.join(OUT, name + ".usdz")
    bpy.ops.object.select_all(action='DESELECT')
    for obj in members(root): obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.wm.usd_export(filepath=path, selected_objects_only=True, export_materials=True, export_meshes=True, export_uvmaps=True, export_normals=True, export_hair=False, export_armatures=False, root_prim_path="/", convert_orientation=False)
    print("EXPORTED", path, os.path.getsize(path) if os.path.exists(path) else -1)

export(garage_root, "BlackridgeGarage")
export(road_root, "BlackridgeRoadSegment")
