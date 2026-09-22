"""Build the Paradise settlement interior blockout -- the first real interior asset beyond a
data contract (Docs/PRODUCTION_CONTENT_HANDOFF.md lists interiors as "data contracts only").

Deterministic and low-poly like build_environment.py's garage/road assets, so it can be
regenerated in CI. It is a replaceable environment asset, not a claim of final art.
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
GENERATED_DIR = os.path.join(SCRIPT_DIR, "generated")
TEX_DIR = os.path.join(GENERATED_DIR, "textures")

sys.path.insert(0, SCRIPT_DIR)
import proc_textures as pt

PATH_WOOD = pt.save_texture(TEX_DIR, "tex_int_wood", pt.wood_texture, size=512)
PATH_PLASTER = pt.save_texture(TEX_DIR, "tex_int_plaster", pt.plaster_texture, size=512)
PATH_METAL = pt.save_texture(TEX_DIR, "tex_int_metal", pt.rusted_metal_texture, size=512)
PATH_CLOTH = pt.save_texture(TEX_DIR, "tex_int_cloth", lambda xs, ys: pt.fabric_texture(xs, ys, tone=(0.42, 0.12, 0.1)), size=256)


def mat(name, color, metallic=0.0, roughness=0.65, emission=None, texture_path=None):
    m = pt.make_material(name, color, metallic=metallic, roughness=roughness, texture_path=texture_path)
    if emission:
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = 2.0
    return m


WOOD = mat("Interior_Wood", (0.28, 0.18, 0.09), roughness=0.75, texture_path=PATH_WOOD)
PLASTER = mat("Interior_Plaster", (0.55, 0.52, 0.46), roughness=0.85, texture_path=PATH_PLASTER)
METAL = mat("Interior_Metal", (0.3, 0.3, 0.32), metallic=0.7, roughness=0.4, texture_path=PATH_METAL)
CLOTH = mat("Interior_Cloth", (0.42, 0.12, 0.1), roughness=0.9, texture_path=PATH_CLOTH)
LAMP = mat("Interior_Lamp", (0.05, 0.04, 0.02), emission=(1.0, 0.7, 0.35))


def cube(name, size, location, material, parent=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    if parent:
        o.parent = parent
    if bevel:
        mod = o.modifiers.new("EdgeBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return o


def cylinder(name, radius, depth, location, material, rotation=(0, 0, 0), vertices=16, parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    if parent:
        o.parent = parent
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def empty(name):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    return e


def paradise_interior():
    # Trading hall: floor/walls, a trade counter (matches the negotiate/trade/recruit Rev10
    # beats that happen inside this interior), bench seating, and interior lighting.
    root = empty("ParadiseInterior_Assembly")
    cube("interior_floor", (12, 10, 0.15), (0, 0, -0.075), WOOD, root)
    cube("interior_back_wall", (12, 0.2, 4.0), (0, 5, 2.0), PLASTER, root)
    cube("interior_left_wall", (0.2, 10, 4.0), (-6, 0, 2.0), PLASTER, root)
    cube("interior_right_wall", (0.2, 10, 4.0), (6, 0, 2.0), PLASTER, root)
    cube("interior_ceiling_beam_a", (12, 0.2, 0.25), (0, -2, 3.9), METAL, root)
    cube("interior_ceiling_beam_b", (12, 0.2, 0.25), (0, 2, 3.9), METAL, root)

    # trade counter, roughly centered, facing the entrance (negative Y)
    cube("trade_counter", (3.4, 0.8, 1.05), (0, 1.5, 0.53), WOOD, root, 0.03)
    cube("trade_counter_top", (3.6, 0.9, 0.08), (0, 1.5, 1.05), METAL, root, 0.02)
    for x in (-1.4, 1.4):
        cylinder("counter_stool_%s" % x, 0.18, 0.5, (x, 2.4, 0.25), METAL, vertices=12, parent=root)

    # bench seating along the side walls
    for x in (-5.2, 5.2):
        cube("bench_%s" % x, (0.5, 3.0, 0.5), (x, -1.5, 0.25), WOOD, root, 0.02)

    # hanging lamps
    for x in (-3, 0, 3):
        cylinder("lamp_%s" % x, 0.22, 0.18, (x, 0, 3.6), LAMP, vertices=16, parent=root)
        cylinder("lamp_cord_%s" % x, 0.015, 0.35, (x, 0, 3.78), METAL, vertices=8, parent=root)

    # a curtained doorway back to the exterior chunk
    cube("doorway_frame_left", (0.25, 0.25, 2.4), (-1.4, -4.9, 1.2), METAL, root)
    cube("doorway_frame_right", (0.25, 0.25, 2.4), (1.4, -4.9, 1.2), METAL, root)
    cube("doorway_curtain", (2.6, 0.06, 2.2), (0, -4.88, 1.1), CLOTH, root)

    return root


def truck_stop_interior():
    # A roadside diner/fuel counter: counter, stools, a short aisle of shelving, and a fuel-pump
    # console visible through a front window opening -- the second interior beyond a data
    # contract (BlackridgeSite.truckStop), reusing the same trading-hall proportions/materials
    # as paradise_interior() rather than inventing a new visual language.
    root = empty("TruckStopInterior_Assembly")
    cube("truckstop_floor", (10, 8, 0.15), (0, 0, -0.075), METAL, root)
    cube("truckstop_back_wall", (10, 0.2, 3.6), (0, 4, 1.8), PLASTER, root)
    cube("truckstop_left_wall", (0.2, 8, 3.6), (-5, 0, 1.8), PLASTER, root)
    cube("truckstop_right_wall", (0.2, 8, 3.6), (5, 0, 1.8), PLASTER, root)
    cube("truckstop_ceiling_beam", (10, 0.2, 0.22), (0, 0, 3.5), METAL, root)

    cube("diner_counter", (4.2, 0.7, 1.0), (-1.0, 1.2, 0.5), METAL, root, 0.03)
    cube("diner_counter_top", (4.4, 0.8, 0.06), (-1.0, 1.2, 1.0), WOOD, root, 0.02)
    for x in (-2.4, -1.4, -0.4, 0.6):
        cylinder("diner_stool_%s" % x, 0.16, 0.5, (x, 2.0, 0.25), METAL, vertices=12, parent=root)

    for x in (2.6, 3.4):
        cube("shelf_unit_%s" % x, (0.6, 1.6, 1.8), (x, -2.0, 0.9), METAL, root, 0.02)

    cube("fuel_console", (1.0, 0.5, 1.1), (3.2, 2.6, 0.55), METAL, root, 0.03)
    cylinder("fuel_console_light", 0.08, 0.1, (3.2, 2.6, 1.15), LAMP, vertices=12, parent=root)

    cube("window_frame", (3.0, 0.15, 1.6), (2.0, -3.9, 1.9), METAL, root)
    cube("front_door_frame", (0.9, 0.15, 2.2), (-3.0, -3.9, 1.1), METAL, root)

    for x in (-3.5, 0, 3.5):
        cylinder("truckstop_lamp_%s" % x, 0.2, 0.16, (x, 0, 3.3), LAMP, vertices=16, parent=root)

    return root


interior_root = paradise_interior()
truckstop_root = truck_stop_interior()
for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.shade_smooth_by_angle()
        o.select_set(False)


def members(root):
    return [o for o in bpy.context.scene.objects if o == root or o.parent == root]


def export(root, name):
    path = os.path.join(OUT, name + ".usdz")
    bpy.ops.object.select_all(action='DESELECT')
    for obj in members(root):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.wm.usd_export(filepath=path, selected_objects_only=True, export_materials=True, export_meshes=True, export_uvmaps=True, export_normals=True, export_hair=False, export_armatures=False, root_prim_path="/", convert_orientation=False)
    print("EXPORTED", path, os.path.exists(path) and os.path.getsize(path))


export(interior_root, "ParadiseInterior")
export(truckstop_root, "TruckStopInterior")
