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
    # dark gunmetal, matching ResearchLibrary/ReferenceImages/ref_side.png's restored-config paint
    base = np.array([0.085, 0.09, 0.10])
    noise = rng.normal(0, 0.012, xs.shape)
    grime = (rng.random(xs.shape) < 0.015) * rng.uniform(-0.08, -0.03, xs.shape)
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

def make_material(name, rgb, metallic=0.0, roughness=0.5, texture_path=None, coat=0.0, coat_roughness=0.05):
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
    if coat > 0:
        bsdf.inputs["Coat Weight"].default_value = coat
        bsdf.inputs["Coat Roughness"].default_value = coat_roughness
    return mat

# dark gunmetal clearcoat paint (matches ref_side.png), real clearcoat via Coat Weight/Roughness
MAT_BODY = make_material("XR13_Paint", (0.085, 0.09, 0.10), metallic=0.55, roughness=0.28,
                          texture_path=PATH_PAINT, coat=1.0, coat_roughness=0.04)
MAT_GLASSHOUSE = make_material("XR13_Glasshouse", (0.02, 0.025, 0.03), metallic=0.0, roughness=0.05, coat=1.0, coat_roughness=0.02)
MAT_DARK = make_material("XR13_Dark", (0.035, 0.035, 0.04), metallic=0.2, roughness=0.5, texture_path=PATH_DARK)
MAT_METAL = make_material("XR13_Metal", (0.55, 0.55, 0.58), metallic=0.95, roughness=0.22, texture_path=PATH_METAL)
MAT_RUBBER = make_material("XR13_Rubber", (0.012, 0.012, 0.012), metallic=0.0, roughness=0.75, texture_path=PATH_RUBBER)
MAT_CALIPER = make_material("XR13_Caliper", (0.65, 0.05, 0.05), metallic=0.3, roughness=0.35, coat=0.5)
MAT_ARMOR = make_material("XR13_Armor", (0.22, 0.23, 0.24), metallic=0.6, roughness=0.45, texture_path=PATH_METAL)
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

def cyl(name, radius, depth, parent, mat, loc, rot=(0, 0, 0), segs=16, smooth=False):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=segs, location=(0, 0, 0))
    obj = bpy.context.active_object
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = poly.normal.z == 0 or abs(poly.normal.z) < 0.99  # keep flat caps crisp, round the barrel
    return obj

def torus(name, major_r, minor_r, parent, mat, loc, rot=(0, 0, 0), smooth=True):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_r, minor_radius=minor_r,
                                      major_segments=28, minor_segments=10, location=(0, 0, 0))
    obj = bpy.context.active_object
    reparent(obj, name, parent, loc, rot)
    assign_mat(obj, mat)
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
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

def catmull_rom_resample(sections, factor=3):
    """Smoothly resample a control-point list (each a tuple of floats, same length) along its
    own index using Catmull-Rom splines per-component, instead of the sharp linear facets a
    direct loft between few control points produces. Endpoints are clamped (tangent from the
    single adjacent point) so the nose/tail tips stay put."""
    pts = np.array(sections, dtype=np.float64)
    n = len(pts)
    out = []
    for i in range(n - 1):
        p0 = pts[i - 1] if i - 1 >= 0 else pts[i]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[i + 2] if i + 2 < n else pts[i + 1]
        steps = factor if i < n - 2 else factor + 1
        for s in range(steps):
            t = s / factor
            t2, t3 = t * t, t * t * t
            row = 0.5 * ((2 * p1) + (-p0 + p2) * t
                         + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                         + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
            out.append(tuple(row))
    return out

def loft(name, sections, parent, mat, loc=(0, 0, 0), ring_fn=None, smooth=False):
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
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj

# ---------- assembly hierarchy ----------
assembly = new_empty("XR13_Assembly")
chassis_root = new_empty("chassis", parent=assembly)

# ride height: wheel-center height, and chassis floor reference. Must exceed the tire's outer
# radius (major_radius + minor_radius, see the wheel definitions below) or the wheels sink through
# the ground plane -- caught by measuring proportions against the reference images and checking
# the numbers. Lowered from 0.50 to 0.45 alongside the wheel-size reduction below (new outer
# radius 0.36+0.065=0.425, so 0.45 still clears it with a small margin).
GROUND = 0.45

# ================= BODY SHELL: long hood, wide rear haunches, low fastback beltline =================
# (x, half_width, top_z) -- top_z is the beltline the greenhouse sits on; the body itself stays
# low and wide (muscular shoulders), with pronounced flares at both wheel arches.
# Measured wheelbase/length and overhang/length ratios directly against ref_side.png (front/rear
# wheel-center columns vs. nose/tail columns): reference wheelbase/length ~0.696, this model's
# previous 1.35/-1.75 wheel positions gave only 0.549 -- overhangs both front and rear were much
# longer than the reference's short-overhang fastback stance. Fender-flare control points moved
# to track the new wheel-aligned x positions below.
# The previous pass calibrated wheelbase/length to 0.696 by pixel-reading ref_side.png directly,
# but that contradicts well-established real Mustang/Shelby GT500 dimensions (the reference car is
# clearly a modified GT500): wheelbase/length ~0.569, height/wheelbase ~0.508, wheel-diameter/
# wheelbase ~0.254 (2720mm wheelbase, 4784mm length, 1381mm height, ~691mm wheel diameter). Those
# are authoritative and not subject to the pixel-measurement noise a ~130px-tall crop has -- the
# 0.696 reading was the error, not the real-world ratio. Recalibrated against these instead: with
# this model's 5.65-unit nose-to-tail length, target wheelbase is 0.569*5.65=3.21 (front overhang
# ~1.11, rear overhang ~1.32, split matching the real car's slightly-larger rear overhang), giving
# front wheel x=1.75 (barely moved from the previous pass) and rear wheel x=-1.48 (moved back from
# the previous pass's overcorrected -2.19). Target total height is 0.508*3.21=1.63 (see GROUND and
# green_sections below for how that's split between the body and the greenhouse).
body_sections = [
    (2.85, 0.03, 0.26),    # nose tip
    (2.60, 0.62, 0.34),    # front bumper
    (2.35, 0.90, 0.40),    # headlight line
    (1.95, 0.97, 0.46),    # long hood
    (1.75, 1.06, 0.46),    # front fender flare (over front wheel, x matches new wheel position)
    (1.00, 0.98, 0.50),    # cowl
    (-0.20, 0.96, 0.50),   # beltline mid / rocker
    (-1.45, 1.10, 0.46),   # rear fender flare (over rear wheel; widest point -- muscular haunch)
    (-1.85, 0.90, 0.42),   # decklid
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
body_sections_smooth = catmull_rom_resample(body_sections, factor=4)
body_shell = loft("bodyShell", body_sections_smooth, body_panels, MAT_BODY, ring_fn=body_ring, smooth=True)
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
# Pixel-grid measurement against ref_side.png (ground/beltline/roof-peak rows) shows the
# greenhouse rising roughly as tall as the lower body below the beltline, not a shallow bump --
# roof_z raised accordingly from the previous pass's 0.84 to ~1.00.
# Target total vehicle height (real GT500 height/wheelbase ~0.508 * this model's 3.21 wheelbase)
# is ~1.63; with GROUND=0.45 and the body's beltline at local 0.50 (world 0.95), the greenhouse
# needs to rise to local ~1.18 (world ~1.63), not the previous 1.00 (world 1.45, ~0.18 short).
# True front/rear orthogonal renders (not just the 3/4 angles checked before) showed the
# roof_z=1.18 height reached for the real-GT500 height/wheelbase ratio, combined with the
# greenhouse's half_w=0.80 being much narrower than the body below it (0.90-1.06), made the
# greenhouse read as an isolated narrow fin/tower rather than an integrated roof -- a real defect
# the side-view-only checks in the previous pass missed. Widened to fill more of the body width and
# brought the height down partway back toward the previous pass's 1.00 (a compromise: still taller
# than 1.00, short of the real-ratio-derived 1.18, chosen because the front/rear silhouette is what
# visibly broke, and no single number here perfectly satisfies both the side-profile height ratio
# and the front-view width/height balance on a 4-point cross-section).
green_sections = [
    (0.95, 0.94, 0.50, 0.58),    # windshield base
    (0.45, 0.98, 0.50, 0.98),    # roof front (A-pillar)
    (-0.90, 0.98, 0.50, 0.98),   # roof rear -- wide flat plateau (0.45 -> -0.90) so the roof
                                 # reads as a roof at full-car scale, not a short tent apex
    (-1.45, 0.94, 0.44, 0.48),   # long, shallow fastback taper into the decklid (x matches the
                                 # new rear fender-flare position)
]

def green_ring(half_w, base_z, roof_z):
    # a much flatter top than a 0.7-factor trapezoid gives: a real roof panel, not a tent ridge.
    # The side-wall taper factor was 0.92 (roof narrower than base); from a true front/rear
    # orthogonal render that read as a pyramid/tent silhouette, not an integrated cabin -- nearly
    # vertical sides (0.98) look like an actual greenhouse box instead.
    return [
        (-half_w, base_z),
        (-half_w * 0.98, roof_z),
        (half_w * 0.98, roof_z),
        (half_w, base_z),
    ]

# NOT Catmull-Rom-resampled, unlike the body shell: the greenhouse's sharp windshield-to-roof
# rise (0.60 -> 1.00 over one segment) makes a Catmull-Rom spline overshoot well past the 1.00
# roof control point -- measured at z=1.557 in the exported mesh, ~0.56 above the intended flat
# roof, which floated the roof-mounted armor/cargo rack (positioned for the intended height) in
# open air above the actual roof. Linear sections avoid the overshoot; smooth shading alone still
# softens the faceting.
greenhouse = loft("greenhouse", green_sections, body_panels, MAT_GLASSHOUSE, ring_fn=green_ring, smooth=True)

# hood vents (reference shows low hood vents/scoop, not one tall bulge).
# Bug: this is parented to body_panels, which already translates by (0,0,GROUND) -- using
# "GROUND + 0.475" as this object's own (local) z on top of that double-added GROUND, putting it
# at world z = 2*GROUND + 0.475 (1.475 with GROUND=0.50) versus the hood's actual surface at
# world z~0.961. That's what was floating disconnected above the car in renders. This location is
# already local to body_panels, so it only needs the local offset (measured against the actual
# hood surface, not a second GROUND term).
for side in (-1, 1):
    box(f"hoodVent_{'L' if side < 0 else 'R'}", (0.28, 0.14, 0.045), body_panels, MAT_DARK,
        loc=(1.55, side * 0.28, 0.46))

# front splitter (low aero lip ahead of the bumper) and push bar.
# The previous span (2.55 -> 2.95) reached the pinched nose tip (body half-width there is only
# 0.03-0.14) at a fixed 0.68 half-width, so most of the splitter stuck out past the actual body
# surface -- visible in a top-down render as a rectangle poking off the side of the car. Pulled
# back to sit under the wide bumper region instead (body half-width ~0.62-0.90 across this span)
# and narrowed so it stays inside that footprint.
wedge("frontSplitter",
      [(-0.55, 0.0), (-0.55, 0.03), (0.55, 0.03), (0.55, 0.0)],
      2.30, 2.60, chassis_root, MAT_DARK, mat_pos=(0, 0, GROUND + 0.06))
cyl("pushBar", 0.03, 1.2, chassis_root, MAT_METAL, loc=(2.70, 0, GROUND + 0.24), rot=(math.radians(90), 0, 0), smooth=True)
for side in (-1, 1):
    cyl(f"pushBarUpright_{'L' if side < 0 else 'R'}", 0.025, 0.20, chassis_root, MAT_METAL,
        loc=(2.70, side * 0.58, GROUND + 0.14))

# deep front grille opening (reference: a large dark lower opening, not a flat painted panel).
# Measured against the actual body-shell mesh: at x=2.66 the nose has already tapered too
# narrow/curved to hold a flat box without it poking through the surface (this was the cause of
# the grille/slats appearing to float disconnected in front of the nose); x=2.50 is still forward
# fascia but wide and flat enough (body half-width ~0.79, top z ~0.87 there) to sit the opening
# and its slats inside the surface instead of through it.
box("grilleOpening", (0.10, 0.60, 0.18), chassis_root, MAT_DARK, loc=(2.50, 0, GROUND + 0.20))

# rear diffuser fins + dual exhaust tips
# Measured against the body-shell mesh: at the previous x=-2.55/-2.70 the tail has already
# tapered to half-width ~0.50/~0.19, well inside the fins' +-0.55 and the exhaust tips' +-0.35
# spread -- both poked out past the actual tapered surface (visible as detached geometry hovering
# past the tail in a render). Pulled forward to x=-2.40, inside the wider rear-bumper region
# (body half-width ~0.65-0.82 there), and narrowed to stay inside that footprint.
for i, y in enumerate((-0.50, -0.18, 0.18, 0.50)):
    box(f"diffuserFin_{i}", (0.4, 0.03, 0.10), chassis_root, MAT_DARK,
        loc=(-2.40, y, GROUND + 0.12), rot=(0, math.radians(8), 0))
for side in (-1, 1):
    cyl(f"exhaustTip_{'L' if side < 0 else 'R'}", 0.055, 0.14, chassis_root, MAT_METAL,
        loc=(-2.40, side * 0.30, GROUND + 0.10), rot=(0, math.radians(90), 0), smooth=True)

# ducktail lip spoiler on the decklid trailing edge (reference: a small integrated lip, not a
# strut-mounted wing)
box("deckLip", (0.22, 1.15, 0.03), chassis_root, MAT_DARK, loc=(-1.95, 0, GROUND + 0.475),
    rot=(0, math.radians(-6), 0))

# headlights and quad taillights (reference: two round-ish lamps per side, not one block).
# Measured: at x=2.55 the body's top surface reaches only ~GROUND+0.356 (world 0.856 with
# GROUND=0.50); GROUND+0.36 put the box mostly above that surface (visible as a detached white
# wedge floating over the fender). Lowered to embed it within the body height instead.
for side in (-1, 1):
    box(f"headlight_{'L' if side < 0 else 'R'}", (0.06, 0.22, 0.14), chassis_root, MAT_LIGHT,
        loc=(2.55, side * 0.55, GROUND + 0.28))
    # Reference (ref_rear.png) shows wide taillight clusters near the trunk's outer corners, not
    # small central dots -- widened and moved outward to match.
    box(f"taillight_{'L' if side < 0 else 'R'}", (0.05, 0.22, 0.10), chassis_root, MAT_CALIPER,
        loc=(-2.35, side * 0.68, GROUND + 0.42))

# grille mesh: horizontal slats set into the opening (parts reference calls out a distinct
# "grille mesh" sub-assembly, not a painted-over opening); repositioned with grilleOpening above.
for i, z in enumerate(np.linspace(-0.07, 0.07, 6)):
    box(f"grilleSlat_{i}", (0.02, 0.52, 0.012), chassis_root, MAT_DARK,
        loc=(2.46, 0, GROUND + 0.20 + z))

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
# Measured: at x=1.55 the hood surface tops out at ~GROUND+0.461 (world 0.961). The old
# supercharger position (engine_bay z + local 0.42 + radius 0.15 = world 1.13) poked ~0.17 above
# that with no scoop housing to cover it, rendering as a disconnected grey dome floating over the
# hood. Lowered so it sits fully enclosed under the hood instead (there's no scoop mesh here to
# justify a visible bulge -- hoodVent below represents the intake cue at the surface).
cyl("supercharger", 0.15, 0.28, engine_bay, MAT_METAL, loc=(0, 0, 0.15), rot=(math.radians(90), 0, 0), smooth=True)
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
corners = [("FL", 1.75, 0.92), ("FR", 1.75, -0.92), ("RL", -1.48, 0.92), ("RR", -1.48, -0.92)]
for tag, x, y in corners:
    cyl(f"arm_{tag}", 0.025, 0.5, suspension, MAT_DARK, loc=(x, y * 0.5, GROUND - 0.10), rot=(0, math.radians(90), 0))
    cyl(f"coil_{tag}", 0.065, 0.30, suspension, MAT_METAL, loc=(x, y * 0.86, GROUND + 0.06))

# ================= WHEELS (big wheels/brakes: visible rotor + caliper inside the rim) =================
wheels = new_empty("wheels", parent=chassis_root)

def make_wheel(name, x, y):
    grp = new_empty(name, parent=wheels, loc=(x, y, GROUND))
    face_sign = -y / abs(y)  # outward-facing side, so spokes/caliper sit on the visible face
    # Measured wheel-diameter/length against ref_side.png: reference ~0.110, this model's
    # previous 0.40/0.075 tire (outer radius 0.475) gave ~0.168 -- oversized relative to the car.
    # Scaled down ~10% here (and GROUND alongside it) rather than all the way to the reference
    # ratio, to keep the "big wheels" character the canon doc calls for while closing most of the
    # gap.
    torus(name + "_tire", 0.36, 0.065, grp, MAT_RUBBER, loc=(0, 0, 0), rot=(math.radians(90), 0, 0))
    torus(name + "_barrel", 0.28, 0.09, grp, MAT_METAL, loc=(0, 0, 0), rot=(math.radians(90), 0, 0))
    cyl(name + "_hub", 0.068, 0.17, grp, MAT_METAL, loc=(0, 0, 0), rot=(math.radians(90), 0, 0), segs=16, smooth=True)
    # multi-spoke face (5 spokes) on the outward side, instead of a flat blank disc
    for k in range(5):
        ang = k * (2 * math.pi / 5)
        sx, sz = 0.18 * math.cos(ang), 0.18 * math.sin(ang)
        # box's long axis (local Z) needs to point radially in the wheel's XZ face plane;
        # rotating about Y by (90deg - ang) maps local +Z to (cos ang, 0, sin ang)
        box(f"{name}_spoke_{k}", (0.05, 0.022, 0.27), grp, MAT_METAL,
            loc=(sx, face_sign * 0.085, sz), rot=(0, math.pi / 2 - ang, 0))
    cyl(name + "_rotor", 0.17, 0.018, grp, MAT_METAL, loc=(0, -face_sign * 0.072, 0), rot=(math.radians(90), 0, 0), segs=24, smooth=True)
    box(name + "_caliper", (0.09, 0.054, 0.09), grp, MAT_CALIPER, loc=(0.126, -face_sign * 0.126, 0))
    return grp

make_wheel("wheel_0_0", 1.75, 0.92)
make_wheel("wheel_0_1", 1.75, -0.92)
make_wheel("wheel_1_0", -1.48, 0.92)
make_wheel("wheel_1_1", -1.48, -0.92)

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
armor = new_empty("armor", parent=chassis_root, loc=(0, 0, GROUND + 0.985))
box("roofBrace", (1.25, 0.58, 0.02), armor, MAT_ARMOR, loc=(-0.20, 0, 0))

# ================= CARGO RACK (roof-mounted, wasteland module; sits just above the roof brace) =================
cargo = new_empty("cargo", parent=chassis_root, loc=(-0.40, 0, GROUND + 1.005))
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
