import bpy, bmesh, math, os

bpy.ops.wm.read_factory_settings(use_empty=True)

def make_material(name, rgb, metallic=0.0, roughness=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

MAT_BODY = make_material("XR13_Paint", (0.55, 0.07, 0.07), metallic=0.35, roughness=0.4)
MAT_DARK = make_material("XR13_Dark", (0.05, 0.05, 0.06), metallic=0.2, roughness=0.6)
MAT_METAL = make_material("XR13_Metal", (0.35, 0.35, 0.38), metallic=0.9, roughness=0.35)
MAT_GLASS = make_material("XR13_Glass", (0.05, 0.08, 0.1), metallic=0.0, roughness=0.05)
MAT_RUBBER = make_material("XR13_Rubber", (0.015, 0.015, 0.015), metallic=0.0, roughness=0.85)
MAT_ARMOR = make_material("XR13_Armor", (0.22, 0.23, 0.24), metallic=0.6, roughness=0.5)
MAT_CARGO = make_material("XR13_Cargo", (0.3, 0.2, 0.1), metallic=0.1, roughness=0.7)

def new_empty(name, parent=None, loc=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.05
    bpy.context.scene.collection.objects.link(e)
    e.location = loc
    if parent:
        e.parent = parent
    return e

def assign_mat(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)

def reparent(obj, name, parent, loc, rot=(0, 0, 0)):
    obj.name = name
    obj.data.name = name + "_mesh"
    obj.location = loc
    obj.rotation_euler = rot
    obj.parent = parent
    bpy.context.scene.collection.objects.link(obj) if obj.name not in bpy.context.scene.collection.objects else None
    return obj

def box(name, size, parent, mat, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.scale = size
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    return obj

def cyl(name, radius, depth, parent, mat, loc, rot=(0, 0, 0), segs=16):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=segs, location=(0, 0, 0))
    obj = bpy.context.active_object
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    return obj

def torus(name, major_r, minor_r, parent, mat, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_r, minor_radius=minor_r,
                                      major_segments=24, minor_segments=10, location=(0, 0, 0))
    obj = bpy.context.active_object
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    return obj

# ---------- assembly hierarchy ----------
assembly = new_empty("XR13_Assembly")
chassis_root = new_empty("chassis", parent=assembly)

GROUND = 0.36  # ride height: wheel-center height, and chassis floor reference

# ================= BODY SHELL (lofted hull) =================
# cross sections: (x, half_width, belt_z, roof_z) -- belt/roof measured from chassis floor (GROUND)
sections = [
    (2.55, 0.03, 0.20, 0.20),   # nose tip
    (2.30, 0.62, 0.28, 0.28),   # front bumper/grille
    (1.80, 0.86, 0.36, 0.36),   # hood front
    (1.00, 0.90, 0.42, 0.42),   # cowl
    (0.62, 0.86, 0.46, 0.46),   # windshield base
    (0.15, 0.80, 0.46, 0.78),   # roof front (A-pillar)
    (-1.00, 0.80, 0.46, 0.78),  # roof rear (fastback greenhouse)
    (-1.55, 0.86, 0.42, 0.42),  # decklid
    (-2.10, 0.80, 0.32, 0.32),  # rear bumper
    (-2.45, 0.08, 0.20, 0.20),  # tail tip
]

def ring_points(half_w, belt_z, roof_z):
    return [
        (-half_w * 0.30, 0.0),
        (-half_w, belt_z * 0.45),
        (-half_w, belt_z),
        (-half_w * 0.55, roof_z),
        (half_w * 0.55, roof_z),
        (half_w, belt_z),
        (half_w, belt_z * 0.45),
        (half_w * 0.30, 0.0),
    ]

bm = bmesh.new()
ring_verts = []
for (x, hw, bz, rz) in sections:
    pts = ring_points(hw, bz, rz)
    verts = [bm.verts.new((x, y, z)) for (y, z) in pts]
    ring_verts.append(verts)

n = len(ring_verts[0])
for a, b in zip(ring_verts, ring_verts[1:]):
    for i in range(n):
        v0, v1 = a[i], a[(i + 1) % n]
        v2, v3 = b[i], b[(i + 1) % n]
        bm.faces.new((v0, v1, v3, v2))
bm.faces.new(reversed(ring_verts[0]))
bm.faces.new(ring_verts[-1])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)

body_mesh = bpy.data.meshes.new("bodyShell_mesh")
bm.to_mesh(body_mesh)
bm.free()

body_panels = new_empty("bodyPanels", parent=chassis_root, loc=(0, 0, GROUND))
body_shell = bpy.data.objects.new("bodyShell", body_mesh)
bpy.context.scene.collection.objects.link(body_shell)
body_shell.parent = body_panels
body_shell.data.materials.append(MAT_BODY)
bevel = body_shell.modifiers.new("Bevel", "BEVEL")
bevel.width = 0.02
bevel.segments = 2

# No windshield/glass panels: the roof/cowl rings already form an open-cockpit roll-hoop
# silhouette (fitting a stripped-down post-apocalyptic scavenger build), and coincident glass
# planes at the same ring geometry z-fought with the shell's own paint in testing.

# ================= ENGINE BAY =================
engine_bay = new_empty("engineBay", parent=chassis_root, loc=(1.35, 0, GROUND + 0.05))
box("engineBlock", (0.55, 0.48, 0.34), engine_bay, MAT_DARK, loc=(0, 0, 0.17))
cyl("supercharger", 0.14, 0.26, engine_bay, MAT_METAL, loc=(0, 0, 0.40), rot=(math.radians(90), 0, 0))
cyl("radiator", 0.28, 0.09, engine_bay, MAT_METAL, loc=(0.40, 0, 0.15), rot=(0, math.radians(90), 0))

# ================= POWERTRAIN / TRANSMISSION =================
powertrain = new_empty("powertrain", parent=chassis_root, loc=(0, 0, GROUND - 0.05))
cyl("driveshaft", 0.045, 1.6, powertrain, MAT_METAL, loc=(-0.5, 0, 0), rot=(0, math.radians(90), 0))

transmission = new_empty("transmission", parent=chassis_root, loc=(0.55, 0, GROUND - 0.02))
box("dctHousing", (0.42, 0.30, 0.30), transmission, MAT_DARK, loc=(0, 0, 0))

# ================= SUSPENSION =================
suspension = new_empty("suspension", parent=chassis_root)
corners = [("FL", 1.55, 0.78), ("FR", 1.55, -0.78), ("RL", -1.55, 0.78), ("RR", -1.55, -0.78)]
for tag, x, y in corners:
    cyl(f"arm_{tag}", 0.025, 0.45, suspension, MAT_DARK, loc=(x, y * 0.55, GROUND - 0.10), rot=(0, math.radians(90), 0))
    cyl(f"coil_{tag}", 0.06, 0.28, suspension, MAT_METAL, loc=(x, y * 0.82, GROUND + 0.05))

# ================= WHEELS =================
wheels = new_empty("wheels", parent=chassis_root)

def make_wheel(name, x, y):
    grp = new_empty(name, parent=wheels, loc=(x, y, GROUND))
    torus(name + "_tire", 0.34, 0.11, grp, MAT_RUBBER, loc=(0, 0, 0), rot=(math.radians(90), 0, 0))
    cyl(name + "_rim", 0.19, 0.20, grp, MAT_METAL, loc=(0, 0, 0), rot=(math.radians(90), 0, 0), segs=8)
    return grp

make_wheel("wheel_0_0", 1.05, 0.78)
make_wheel("wheel_0_1", 1.05, -0.78)
make_wheel("wheel_1_0", -1.05, 0.78)
make_wheel("wheel_1_1", -1.05, -0.78)

# ================= CABIN =================
cabin = new_empty("cabin", parent=chassis_root, loc=(-0.15, 0, GROUND + 0.46))
box("cabinFloor", (1.45, 0.80, 0.04), cabin, MAT_DARK, loc=(0, 0, -0.02))
box("seatDriver", (0.38, 0.32, 0.26), cabin, MAT_DARK, loc=(0.10, 0.24, 0.14))
box("seatPassenger", (0.38, 0.32, 0.26), cabin, MAT_DARK, loc=(0.10, -0.24, 0.14))

dashboard = new_empty("dashboard", parent=cabin, loc=(0.60, 0, 0.08))
box("dashPanel", (0.08, 0.72, 0.22), dashboard, MAT_DARK, loc=(0, 0, 0))

# ================= ARMOR (conditional plating: a roof roll-brace, sized to the roof span
# so it doesn't overhang into a full canopy) =================
armor = new_empty("armor", parent=chassis_root, loc=(0, 0, GROUND + 0.80))
box("roofBrace", (1.05, 0.55, 0.025), armor, MAT_ARMOR, loc=(-0.42, 0, 0))

# ================= CARGO RACK =================
cargo = new_empty("cargo", parent=chassis_root, loc=(-1.85, 0, GROUND + 0.46))
box("rackBed", (0.75, 0.85, 0.04), cargo, MAT_CARGO, loc=(0, 0, 0.02))
for side in (-1, 1):
    cyl("rackRail" + ("L" if side < 0 else "R"), 0.018, 0.75, cargo, MAT_METAL,
        loc=(0, side * 0.40, 0.08), rot=(math.radians(90), 0, 0))

# ---------- export ----------
out_dir = "/private/tmp/claude-501/-Users-serendipity-Claudeprojx-KINGMAKER/4ddf6449-8a9b-4968-92c3-06111edf9b3f/scratchpad"
os.makedirs(out_dir, exist_ok=True)
blend_path = os.path.join(out_dir, "Kingmaker_XR13.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)

usdz_path = os.path.join(out_dir, "Kingmaker_XR13.usdz")
bpy.ops.wm.usd_export(
    filepath=usdz_path,
    selected_objects_only=False,
    export_materials=True,
    export_meshes=True,
    export_uvmaps=True,
    export_normals=True,
    export_hair=False,
    export_armatures=False,
    root_prim_path="/",
    convert_orientation=False,
)
print("EXPORTED:", usdz_path, os.path.exists(usdz_path), os.path.getsize(usdz_path) if os.path.exists(usdz_path) else -1)
