import bpy, bmesh, math, os
import numpy as np

bpy.ops.wm.read_factory_settings(use_empty=True)

# ---------- procedural textures (no external assets; generated with numpy, saved as PNGs) ----------
TEX_DIR = "/private/tmp/claude-501/-Users-serendipity-Claudeprojx-KINGMAKER/4ddf6449-8a9b-4968-92c3-06111edf9b3f/scratchpad/textures"
os.makedirs(TEX_DIR, exist_ok=True)
rng = np.random.default_rng(13)

def save_texture(name, rgb_fn, size=512):
    """rgb_fn(x, y) -> (r,g,b) in [0,1] arrays of shape (size,size)."""
    xs, ys = np.meshgrid(np.linspace(0, 1, size), np.linspace(0, 1, size))
    r, g, b = rgb_fn(xs, ys)
    a = np.ones_like(r)
    pixels = np.dstack([r, g, b, a]).astype(np.float32)
    img = bpy.data.images.new(name, width=size, height=size, alpha=True)
    img.pixels = pixels.flatten()
    path = os.path.join(TEX_DIR, name + ".png")
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    return path

def paint_texture(xs, ys):
    base = np.array([0.58, 0.055, 0.045])
    noise = rng.normal(0, 0.02, xs.shape)
    grime = (rng.random(xs.shape) < 0.015) * rng.uniform(-0.12, -0.04, xs.shape)
    scratch = np.zeros_like(xs)
    for _ in range(14):
        cx, cy, ang, length, width = rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, math.pi), rng.uniform(0.05, 0.22), 0.004
        dx, dy = xs - cx, ys - cy
        along = dx * math.cos(ang) + dy * math.sin(ang)
        perp = -dx * math.sin(ang) + dy * math.cos(ang)
        mask = (np.abs(along) < length) & (np.abs(perp) < width)
        scratch += mask * 0.14
    v = base[:, None, None] + noise[None] + grime[None] + scratch[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]

def metal_texture(xs, ys):
    brushed = np.sin(xs * 400) * 0.02
    noise = rng.normal(0, 0.03, xs.shape)
    rust = (rng.random(xs.shape) < 0.02) * rng.uniform(0.1, 0.3, xs.shape)
    base = 0.42 + brushed + noise
    r = np.clip(base + rust * 0.6, 0, 1)
    g = np.clip(base + rust * 0.3, 0, 1)
    b = np.clip(base, 0, 1)
    return r, g, b

def dark_trim_texture(xs, ys):
    noise = rng.normal(0, 0.015, xs.shape)
    v = np.clip(0.045 + noise, 0, 0.25)
    return v, v, v

def rubber_tread_texture(xs, ys):
    tread = ((xs * 40 + ys * 6).astype(int) % 4 == 0) * 0.05
    noise = rng.normal(0, 0.006, xs.shape)
    v = np.clip(0.012 + tread + noise, 0, 0.2)
    return v, v, v

PATH_PAINT = save_texture("tex_paint", paint_texture, size=512)
PATH_METAL = save_texture("tex_metal", metal_texture, size=512)
PATH_DARK = save_texture("tex_dark", dark_trim_texture, size=256)
PATH_RUBBER = save_texture("tex_rubber", rubber_tread_texture, size=512)

def make_material(name, rgb, metallic=0.0, roughness=0.5, texture_path=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if texture_path:
        img = bpy.data.images.load(texture_path)
        tex_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex_node.image = img
        mat.node_tree.links.new(tex_node.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

MAT_BODY = make_material("XR13_Paint", (0.58, 0.06, 0.05), metallic=0.4, roughness=0.35, texture_path=PATH_PAINT)
MAT_GLASSHOUSE = make_material("XR13_Glasshouse", (0.07, 0.09, 0.11), metallic=0.1, roughness=0.2)
MAT_DARK = make_material("XR13_Dark", (0.045, 0.045, 0.05), metallic=0.2, roughness=0.6, texture_path=PATH_DARK)
MAT_METAL = make_material("XR13_Metal", (0.4, 0.4, 0.43), metallic=0.9, roughness=0.3, texture_path=PATH_METAL)
MAT_RUBBER = make_material("XR13_Rubber", (0.012, 0.012, 0.012), metallic=0.0, roughness=0.85, texture_path=PATH_RUBBER)
MAT_CALIPER = make_material("XR13_Caliper", (0.65, 0.05, 0.05), metallic=0.3, roughness=0.4)
MAT_ARMOR = make_material("XR13_Armor", (0.22, 0.23, 0.24), metallic=0.6, roughness=0.5, texture_path=PATH_METAL)
MAT_CARGO = make_material("XR13_Cargo", (0.3, 0.2, 0.1), metallic=0.1, roughness=0.7)
MAT_LIGHT = make_material("XR13_Light", (0.9, 0.92, 0.85), metallic=0.0, roughness=0.1)

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
                                      major_segments=28, minor_segments=10, location=(0, 0, 0))
    obj = bpy.context.active_object
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    return obj

def wedge(name, verts_2d, x0, x1, parent, mat, mat_pos=(0, 0, 0)):
    """Loft a simple 2-ring wedge (front cross-section -> back cross-section, both same 2D outline
    scaled implicitly by caller) between x0 and x1. verts_2d is a list of (y, z) tuples forming one
    ring, reused at both x positions with independent z passed via callback would be more flexible,
    but for our use (splitter/diffuser fins) both rings share verts_2d directly."""
    bm2 = bmesh.new()
    ring_a = [bm2.verts.new((x0, y, z)) for (y, z) in verts_2d]
    ring_b = [bm2.verts.new((x1, y, z)) for (y, z) in verts_2d]
    n = len(ring_a)
    for i in range(n):
        v0, v1 = ring_a[i], ring_a[(i + 1) % n]
        v2, v3 = ring_b[i], ring_b[(i + 1) % n]
        bm2.faces.new((v0, v1, v3, v2))
    bm2.faces.new(reversed(ring_a))
    bm2.faces.new(ring_b)
    bmesh.ops.recalc_face_normals(bm2, faces=bm2.faces)
    m = bpy.data.meshes.new(name + "_mesh")
    bm2.to_mesh(m)
    bm2.free()
    obj = bpy.data.objects.new(name, m)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.location = mat_pos
    obj.data.materials.append(mat)
    return obj

def loft(name, sections, parent, mat, loc=(0, 0, 0), ring_fn=None):
    """sections: list of (x, half_w, top_z) or richer tuples consumed by ring_fn."""
    bm2 = bmesh.new()
    ring_verts = []
    for s in sections:
        pts = ring_fn(*s[1:])
        verts = [bm2.verts.new((s[0], y, z)) for (y, z) in pts]
        ring_verts.append(verts)
    n = len(ring_verts[0])
    for a, b in zip(ring_verts, ring_verts[1:]):
        for i in range(n):
            v0, v1 = a[i], a[(i + 1) % n]
            v2, v3 = b[i], b[(i + 1) % n]
            bm2.faces.new((v0, v1, v3, v2))
    bm2.faces.new(reversed(ring_verts[0]))
    bm2.faces.new(ring_verts[-1])
    bmesh.ops.recalc_face_normals(bm2, faces=bm2.faces)
    bmesh.ops.remove_doubles(bm2, verts=bm2.verts, dist=1e-5)
    m = bpy.data.meshes.new(name + "_mesh")
    bm2.to_mesh(m)
    bm2.free()
    obj = bpy.data.objects.new(name, m)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.location = loc
    obj.data.materials.append(mat)
    return obj

# ---------- assembly hierarchy ----------
assembly = new_empty("XR13_Assembly")
chassis_root = new_empty("chassis", parent=assembly)

GROUND = 0.36  # ride height: wheel-center height, and chassis floor reference

# ================= BODY SHELL: long hood, wide rear haunches, low fastback beltline =================
# (x, half_width, top_z) -- top_z is the beltline the greenhouse sits on; the body itself stays
# low and wide (muscular shoulders), with pronounced flares at both wheel arches.
body_sections = [
    (2.85, 0.03, 0.26),    # nose tip
    (2.60, 0.62, 0.34),    # front bumper
    (2.35, 0.90, 0.40),    # headlight line
    (1.75, 0.97, 0.46),    # long hood
    (1.35, 1.06, 0.46),    # front fender flare (over front wheel)
    (0.75, 0.98, 0.50),    # cowl
    (-0.20, 0.96, 0.50),   # beltline mid / rocker
    (-1.35, 1.10, 0.46),   # rear fender flare (over rear wheel; widest point -- muscular haunch)
    (-1.95, 0.90, 0.42),   # decklid
    (-2.35, 0.82, 0.36),   # rear bumper
    (-2.80, 0.03, 0.28),   # tail tip
]

def body_ring(half_w, top_z):
    return [
        (-half_w * 0.28, 0.0),
        (-half_w, top_z * 0.42),
        (-half_w, top_z * 0.94),
        (-half_w * 0.6, top_z),
        (half_w * 0.6, top_z),
        (half_w, top_z * 0.94),
        (half_w, top_z * 0.42),
        (half_w * 0.28, 0.0),
    ]

body_panels = new_empty("bodyPanels", parent=chassis_root, loc=(0, 0, GROUND))
body_shell = loft("bodyShell", body_sections, body_panels, MAT_BODY, ring_fn=body_ring)
bevel = body_shell.modifiers.new("Bevel", "BEVEL")
bevel.width = 0.02
bevel.segments = 2

# fastback greenhouse: a distinct, narrower volume stepped up from the beltline, roof flowing
# down into the decklid (the "fastback roof" the visual canon calls for), sitting only over the
# cabin span so the wide rear haunches remain visible outside it.
# Reference (ResearchLibrary/ReferenceImages/ref_side.png) shows a much lower, longer,
# more rakish fastback roofline than a first pass gave it -- roof peak lower relative to
# the body, and the rear glass taper stretched out over a longer run instead of a sharp
# step down into the decklid.
green_sections = [
    (0.95, 0.78, 0.50, 0.56),    # windshield base
    (0.45, 0.80, 0.50, 0.84),    # roof front (A-pillar)
    (-0.90, 0.80, 0.50, 0.84),   # roof rear -- wide flat plateau (0.45 -> -0.90) so the roof
                                 # reads as a roof at full-car scale, not a short tent apex
    (-1.85, 0.84, 0.44, 0.46),   # long, shallow fastback taper into the decklid
]

def green_ring(half_w, base_z, roof_z):
    # a much flatter top than a 0.7-factor trapezoid gives: a real roof panel, not a tent ridge
    return [
        (-half_w, base_z),
        (-half_w * 0.92, roof_z),
        (half_w * 0.92, roof_z),
        (half_w, base_z),
    ]

greenhouse = loft("greenhouse", green_sections, body_panels, MAT_GLASSHOUSE, ring_fn=green_ring)

# hood vents (reference shows low hood vents/scoop, not one tall bulge)
for side in (-1, 1):
    box(f"hoodVent_{'L' if side < 0 else 'R'}", (0.28, 0.14, 0.045), body_panels, MAT_DARK,
        loc=(1.55, side * 0.28, GROUND + 0.475))

# front splitter (low aero lip ahead of the bumper) and push bar
wedge("frontSplitter",
      [(-0.68, 0.0), (-0.68, 0.03), (0.68, 0.03), (0.68, 0.0)],
      2.55, 2.95, chassis_root, MAT_DARK, mat_pos=(0, 0, GROUND + 0.06))
cyl("pushBar", 0.03, 1.2, chassis_root, MAT_METAL, loc=(2.70, 0, GROUND + 0.24), rot=(math.radians(90), 0, 0))
for side in (-1, 1):
    cyl(f"pushBarUpright_{'L' if side < 0 else 'R'}", 0.025, 0.20, chassis_root, MAT_METAL,
        loc=(2.70, side * 0.58, GROUND + 0.14))

# deep front grille opening (reference: a large dark lower opening, not a flat painted panel)
box("grilleOpening", (0.10, 0.62, 0.20), chassis_root, MAT_DARK, loc=(2.66, 0, GROUND + 0.30))

# rear diffuser fins + dual exhaust tips
for i, y in enumerate((-0.55, -0.2, 0.2, 0.55)):
    box(f"diffuserFin_{i}", (0.5, 0.03, 0.10), chassis_root, MAT_DARK,
        loc=(-2.55, y, GROUND + 0.12), rot=(0, math.radians(8), 0))
for side in (-1, 1):
    cyl(f"exhaustTip_{'L' if side < 0 else 'R'}", 0.055, 0.14, chassis_root, MAT_METAL,
        loc=(-2.70, side * 0.35, GROUND + 0.10), rot=(0, math.radians(90), 0))

# ducktail lip spoiler on the decklid trailing edge (reference: a small integrated lip, not a
# strut-mounted wing)
box("deckLip", (0.22, 1.15, 0.03), chassis_root, MAT_DARK, loc=(-1.95, 0, GROUND + 0.475),
    rot=(0, math.radians(-6), 0))

# headlights and quad taillights (reference: two round-ish lamps per side, not one block)
for side in (-1, 1):
    box(f"headlight_{'L' if side < 0 else 'R'}", (0.06, 0.22, 0.14), chassis_root, MAT_LIGHT,
        loc=(2.55, side * 0.55, GROUND + 0.36))
    for j, zz in enumerate((-0.05, 0.05)):
        box(f"taillight_{'L' if side < 0 else 'R'}_{j}", (0.05, 0.10, 0.055), chassis_root, MAT_CALIPER,
            loc=(-2.35, side * 0.55, GROUND + 0.40 + zz))

# grille mesh: horizontal slats set into the opening (parts reference calls out a distinct
# "grille mesh" sub-assembly, not a painted-over opening)
for i, z in enumerate(np.linspace(-0.08, 0.08, 6)):
    box(f"grilleSlat_{i}", (0.02, 0.55, 0.012), chassis_root, MAT_DARK,
        loc=(2.62, 0, GROUND + 0.30 + z))

# door seam lines: thin recessed dark strips on both flanks, marking the door split called out in
# the parts/disassembly reference (front door and rear quarter panel), instead of one uninterrupted
# side surface
for side in (-1, 1):
    y = side * 0.99
    box(f"doorSeam_front_{'L' if side < 0 else 'R'}", (0.012, 0.012, 0.34), body_panels, MAT_DARK,
        loc=(0.55, y, 0.28), rot=(0, 0, 0))
    box(f"doorSeam_rear_{'L' if side < 0 else 'R'}", (0.012, 0.012, 0.34), body_panels, MAT_DARK,
        loc=(-0.85, y, 0.28), rot=(0, 0, 0))

# ================= ENGINE BAY (under the hood, ahead of the cowl) =================
engine_bay = new_empty("engineBay", parent=chassis_root, loc=(1.55, 0, GROUND + 0.06))
box("engineBlock", (0.55, 0.50, 0.34), engine_bay, MAT_DARK, loc=(0, 0, 0.17))
cyl("supercharger", 0.15, 0.28, engine_bay, MAT_METAL, loc=(0, 0, 0.42), rot=(math.radians(90), 0, 0))
cyl("radiator", 0.30, 0.09, engine_bay, MAT_METAL, loc=(0.42, 0, 0.15), rot=(0, math.radians(90), 0))
for side in (-1, 1):
    cyl(f"header_{'L' if side < 0 else 'R'}", 0.03, 0.5, engine_bay, MAT_METAL,
        loc=(-0.15, side * 0.28, 0.05), rot=(0, math.radians(90), 0))

# ================= POWERTRAIN / TRANSMISSION =================
powertrain = new_empty("powertrain", parent=chassis_root, loc=(0, 0, GROUND - 0.05))
cyl("driveshaft", 0.045, 1.9, powertrain, MAT_METAL, loc=(-0.6, 0, 0), rot=(0, math.radians(90), 0))

transmission = new_empty("transmission", parent=chassis_root, loc=(0.60, 0, GROUND - 0.02))
box("dctHousing", (0.42, 0.30, 0.30), transmission, MAT_DARK, loc=(0, 0, 0))

# ================= SUSPENSION (wide track matching the flared haunches) =================
suspension = new_empty("suspension", parent=chassis_root)
corners = [("FL", 1.35, 0.92), ("FR", 1.35, -0.92), ("RL", -1.75, 0.92), ("RR", -1.75, -0.92)]
for tag, x, y in corners:
    cyl(f"arm_{tag}", 0.025, 0.5, suspension, MAT_DARK, loc=(x, y * 0.5, GROUND - 0.10), rot=(0, math.radians(90), 0))
    cyl(f"coil_{tag}", 0.065, 0.30, suspension, MAT_METAL, loc=(x, y * 0.86, GROUND + 0.06))

# ================= WHEELS (big wheels/brakes: visible rotor + caliper inside the rim) =================
wheels = new_empty("wheels", parent=chassis_root)

def make_wheel(name, x, y):
    grp = new_empty(name, parent=wheels, loc=(x, y, GROUND))
    # reference shows a low-profile performance tire: big alloy rim, thin sidewall
    torus(name + "_tire", 0.40, 0.075, grp, MAT_RUBBER, loc=(0, 0, 0), rot=(math.radians(90), 0, 0))
    cyl(name + "_rim", 0.32, 0.21, grp, MAT_METAL, loc=(0, 0, 0), rot=(math.radians(90), 0, 0), segs=12)
    cyl(name + "_rotor", 0.19, 0.02, grp, MAT_METAL, loc=(0, -y / abs(y) * 0.08, 0), rot=(math.radians(90), 0, 0), segs=20)
    box(name + "_caliper", (0.10, 0.06, 0.10), grp, MAT_CALIPER, loc=(0.14, -y / abs(y) * 0.14, 0))
    return grp

make_wheel("wheel_0_0", 1.35, 0.92)
make_wheel("wheel_0_1", 1.35, -0.92)
make_wheel("wheel_1_0", -1.75, 0.92)
make_wheel("wheel_1_1", -1.75, -0.92)

# ================= CABIN (inside the greenhouse: roll cage, seats, pedal box) =================
cabin = new_empty("cabin", parent=chassis_root, loc=(-0.15, 0, GROUND + 0.50))
box("cabinFloor", (1.55, 0.85, 0.04), cabin, MAT_DARK, loc=(0, 0, -0.02))
box("seatDriver", (0.38, 0.32, 0.26), cabin, MAT_DARK, loc=(0.15, 0.26, 0.14))
box("seatPassenger", (0.38, 0.32, 0.26), cabin, MAT_DARK, loc=(0.15, -0.26, 0.14))
# roof peak sits at cabin-local z=0.40 (world GROUND+0.90); keep the cage well under that
for side in (-1, 1):
    cyl(f"rollCage_{'L' if side < 0 else 'R'}", 0.022, 0.26, cabin, MAT_METAL,
        loc=(0, side * 0.75, 0.13), rot=(0, 0, 0))
box("rollCageBar", (1.4, 0.025, 0.025), cabin, MAT_METAL, loc=(0, 0, 0.26))
box("pedalBox", (0.14, 0.20, 0.12), cabin, MAT_DARK, loc=(0.75, 0.15, 0.02))

dashboard = new_empty("dashboard", parent=cabin, loc=(0.62, 0, 0.10))
box("dashPanel", (0.08, 0.78, 0.24), dashboard, MAT_DARK, loc=(0, 0, 0))
cyl("tachometer", 0.05, 0.02, dashboard, MAT_LIGHT, loc=(0.05, 0.20, 0.05), rot=(0, math.radians(90), 0))

# ================= ARMOR (wasteland roof brace/push-bar plating; a roof plate sized to and
# sitting flush on the greenhouse, whose peak is now GROUND+0.90, not the old GROUND+1.00) =================
armor = new_empty("armor", parent=chassis_root, loc=(0, 0, GROUND + 0.845))
box("roofBrace", (1.25, 0.58, 0.02), armor, MAT_ARMOR, loc=(-0.20, 0, 0))

# ================= CARGO RACK (roof-mounted, wasteland module; sits just above the roof brace) =================
cargo = new_empty("cargo", parent=chassis_root, loc=(-0.40, 0, GROUND + 0.865))
box("rackBed", (0.70, 0.80, 0.03), cargo, MAT_CARGO, loc=(0, 0, 0))
for side in (-1, 1):
    cyl("rackRail" + ("L" if side < 0 else "R"), 0.015, 0.70, cargo, MAT_METAL,
        loc=(0, side * 0.38, 0.045), rot=(math.radians(90), 0, 0))

# ---------- UV unwrap every mesh (smart project) so the image textures above map correctly;
# the bmesh-built meshes (bodyShell, greenhouse, splitter, diffuser fins) have no UVs at all until
# this runs, and re-unwrapping the bpy.ops primitives too keeps texel density consistent ----------
for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')

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
