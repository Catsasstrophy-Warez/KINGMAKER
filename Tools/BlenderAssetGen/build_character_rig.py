"""Build a basic humanoid skeletal rig with a walk-cycle animation.

Animation was previously entirely numeric state (e.g. KingmakerWheelAnimationState just tracks a
"wheelSpinRadians" float, nothing renders it) -- there was no skeleton/rig/animation-clip asset
anywhere in the project. This is a real bone-driven rig (an Armature with a hierarchy of posable
bones), not another numeric-state struct: a low-poly mannequin (boxes/capsules per body part,
bone-parented rather than vertex-weight-skinned, which is enough to pose/animate at blockout
fidelity without a full skinning pass) plus a baked walk-cycle animation exported as USD skeletal
animation (export_armatures + export_animation).

Deterministic and low-poly like the other Tools/BlenderAssetGen scripts, so it's reproducible in
CI. This is a placeholder rig, not production character animation -- see
Docs/PRODUCTION_CONTENT_HANDOFF.md's "NPCs/vehicles: rigs, animations" requirement, which this
narrows but does not close (one generic mannequin, one walk cycle, no production character
roster of distinct meshes/rigs).
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

FPS = 24
bpy.context.scene.render.fps = FPS

sys.path.insert(0, SCRIPT_DIR)
import proc_textures as pt

TEX_DIR = os.path.join(SCRIPT_DIR, "generated", "textures")
PATH_SKIN = pt.save_texture(TEX_DIR, "tex_mannequin_skin", lambda xs, ys: pt.skin_texture(xs, ys, tone=(0.65, 0.5, 0.42)), size=256)
PATH_CLOTH = pt.save_texture(TEX_DIR, "tex_mannequin_cloth", lambda xs, ys: pt.fabric_texture(xs, ys, tone=(0.15, 0.16, 0.2)), size=256)


def mat(name, color, texture_path=None):
    return pt.make_material(name, color, roughness=0.6, texture_path=texture_path)


SKIN = mat("Mannequin_Skin", (0.65, 0.5, 0.42), texture_path=PATH_SKIN)
CLOTH = mat("Mannequin_Cloth", (0.15, 0.16, 0.2), texture_path=PATH_CLOTH)

# ---------- armature ----------
bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
armature_obj = bpy.context.object
armature_obj.name = "Mannequin_Armature"
armature = armature_obj.data
armature.name = "Mannequin_Skeleton"
edit_bones = armature.edit_bones
edit_bones.remove(edit_bones[0])  # drop the default single bone, build our own hierarchy

BONES = {
    # name: (head, tail, parent)
    "hips": ((0, 0, 0.95), (0, 0, 1.05), None),
    "spine": ((0, 0, 1.05), (0, 0, 1.35), "hips"),
    "head": ((0, 0, 1.35), (0, 0, 1.60), "spine"),
    "upperarm.L": ((0.18, 0, 1.32), (0.45, 0, 1.15), "spine"),
    "forearm.L": ((0.45, 0, 1.15), (0.68, 0, 1.00), "upperarm.L"),
    "upperarm.R": ((-0.18, 0, 1.32), (-0.45, 0, 1.15), "spine"),
    "forearm.R": ((-0.45, 0, 1.15), (-0.68, 0, 1.00), "upperarm.R"),
    "upperleg.L": ((0.10, 0, 0.95), (0.10, 0, 0.50), "hips"),
    "lowerleg.L": ((0.10, 0, 0.50), (0.10, 0, 0.05), "upperleg.L"),
    "upperleg.R": ((-0.10, 0, 0.95), (-0.10, 0, 0.50), "hips"),
    "lowerleg.R": ((-0.10, 0, 0.50), (-0.10, 0, 0.05), "upperleg.R"),
}
created = {}
for name, (head, tail, parent) in BONES.items():
    b = edit_bones.new(name)
    b.head = head
    b.tail = tail
    if parent:
        b.parent = created[parent]
        b.use_connect = False
    created[name] = b

bpy.ops.object.mode_set(mode='OBJECT')


def part(name, size, location, material, bone):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    o.parent = armature_obj
    o.parent_type = 'BONE'
    o.parent_bone = bone
    # Blender's BONE parenting places the child at the bone's TAIL in the bone's local space;
    # offset back to the bone's midpoint so each mannequin part visually covers its bone.
    head, tail, _ = BONES[bone]
    mid = tuple((h + t) / 2 for h, t in zip(head, tail))
    bone_len = math.dist(head, tail)
    o.location = (0, -bone_len / 2, 0)
    return o


part("torso", (0.34, 0.2, 0.42), (0, 0, 1.18), CLOTH, "spine")
part("pelvis", (0.30, 0.22, 0.14), (0, 0, 0.98), CLOTH, "hips")
part("head_mesh", (0.20, 0.20, 0.24), (0, 0, 1.47), SKIN, "head")
part("upperarm_L", (0.10, 0.10, 0.32), (0.315, 0, 1.235), SKIN, "upperarm.L")
part("forearm_L", (0.085, 0.085, 0.28), (0.565, 0, 1.075), SKIN, "forearm.L")
part("upperarm_R", (0.10, 0.10, 0.32), (-0.315, 0, 1.235), SKIN, "upperarm.R")
part("forearm_R", (0.085, 0.085, 0.28), (-0.565, 0, 1.075), SKIN, "forearm.R")
part("upperleg_L", (0.14, 0.14, 0.44), (0.10, 0, 0.725), CLOTH, "upperleg.L")
part("lowerleg_L", (0.11, 0.11, 0.44), (0.10, 0, 0.275), SKIN, "lowerleg.L")
part("upperleg_R", (0.14, 0.14, 0.44), (-0.10, 0, 0.725), CLOTH, "upperleg.R")
part("lowerleg_R", (0.11, 0.11, 0.44), (-0.10, 0, 0.275), SKIN, "lowerleg.R")

# ---------- walk-cycle animation (1 second, 24 frames, looping) ----------
bpy.context.view_layer.objects.active = armature_obj
bpy.ops.object.mode_set(mode='POSE')
pose_bones = armature_obj.pose.bones
for bone in pose_bones:
    # Default rotation_mode is QUATERNION; keying rotation_euler with that mode active leaves
    # rotation_quaternion (what pose evaluation and the USD exporter actually sample) untouched,
    # so the bake silently produces zero animated samples. Force Euler so our keyframes drive it.
    bone.rotation_mode = 'XYZ'

WALK_FRAMES = 24
SWING_DEG = 28


def keyframe_swing(bone_name, axis_index, amplitude_deg, phase, frame, total_frames=None):
    total_frames = total_frames or WALK_FRAMES
    bone = pose_bones[bone_name]
    angle = math.radians(amplitude_deg) * math.sin(2 * math.pi * (frame / total_frames) + phase)
    euler = list(bone.rotation_euler)
    euler[axis_index] = angle
    bone.rotation_euler = euler
    bone.keyframe_insert(data_path="rotation_euler", frame=frame, index=axis_index)


for frame in range(WALK_FRAMES + 1):
    keyframe_swing("upperleg.L", 0, SWING_DEG, 0, frame)
    keyframe_swing("upperleg.R", 0, SWING_DEG, math.pi, frame)
    keyframe_swing("upperarm.L", 0, SWING_DEG * 0.7, math.pi, frame)
    keyframe_swing("upperarm.R", 0, SWING_DEG * 0.7, 0, frame)
    keyframe_swing("lowerleg.L", 0, SWING_DEG * 0.5, math.pi / 2, frame)
    keyframe_swing("lowerleg.R", 0, SWING_DEG * 0.5, math.pi / 2 + math.pi, frame)

if armature_obj.animation_data and armature_obj.animation_data.action:
    armature_obj.animation_data.action.name = "WalkCycle"

bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = WALK_FRAMES

for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.shade_smooth_by_angle()
        o.select_set(False)

# ---------- export ----------
path = os.path.join(OUT, "Mannequin_WalkCycle.usdz")
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.usd_export(
    filepath=path,
    selected_objects_only=True,
    export_animation=True,
    export_armatures=True,
    export_materials=True,
    export_meshes=True,
    export_uvmaps=True,
    export_normals=True,
    root_prim_path="/",
    convert_orientation=False,
)
print("EXPORTED", path, os.path.exists(path) and os.path.getsize(path))

# ---------- idle animation (separate action, separate export) ----------
# The rig previously had exactly one clip (WalkCycle) -- a player avatar standing still had no
# animation to play at all. This adds a second, much subtler clip: a slow breathing/weight-shift
# sway, not another walk-style limb swing, so a stationary player reads as alive rather than
# frozen. Built as its own Blender action and exported to its own USDZ (Mannequin_Idle.usdz)
# rather than layered into the walk clip, matching the one-clip-per-file pattern the manifest
# already expects for player.walk/player.interact/kingmaker.start.
bpy.context.view_layer.objects.active = armature_obj
bpy.ops.object.mode_set(mode='POSE')
for bone in pose_bones:
    bone.rotation_mode = 'XYZ'
    bone.rotation_euler = (0, 0, 0)

idle_action = bpy.data.actions.new("Idle")
armature_obj.animation_data.action = idle_action

IDLE_FRAMES = 72
IDLE_DEG = 3.0

for frame in range(IDLE_FRAMES + 1):
    keyframe_swing("spine", 0, IDLE_DEG, 0, frame, total_frames=IDLE_FRAMES)
    keyframe_swing("spine", 2, IDLE_DEG * 0.5, math.pi / 2, frame, total_frames=IDLE_FRAMES)
    keyframe_swing("head", 1, IDLE_DEG * 0.4, math.pi / 3, frame, total_frames=IDLE_FRAMES)
    keyframe_swing("upperarm.L", 2, IDLE_DEG * 0.7, 0, frame, total_frames=IDLE_FRAMES)
    keyframe_swing("upperarm.R", 2, IDLE_DEG * 0.7, math.pi, frame, total_frames=IDLE_FRAMES)
    keyframe_swing("hips", 2, IDLE_DEG * 0.3, math.pi / 4, frame, total_frames=IDLE_FRAMES)

idle_action.name = "Idle"
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = IDLE_FRAMES
bpy.ops.object.mode_set(mode='OBJECT')

idle_path = os.path.join(OUT, "Mannequin_Idle.usdz")
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.usd_export(
    filepath=idle_path,
    selected_objects_only=True,
    export_animation=True,
    export_armatures=True,
    export_materials=True,
    export_meshes=True,
    export_uvmaps=True,
    export_normals=True,
    root_prim_path="/",
    convert_orientation=False,
)
print("EXPORTED", idle_path, os.path.exists(idle_path) and os.path.getsize(idle_path))
