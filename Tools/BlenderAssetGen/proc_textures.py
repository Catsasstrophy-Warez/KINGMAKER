"""Shared procedural-texture and PBR-material helpers for Tools/BlenderAssetGen/ scripts.

Before this, only build_kingmaker.py generated numpy-authored PBR textures (paint/metal/rubber
with noise, scratches, rust speckle) -- every other script (build_environment.py,
build_interior.py, build_secondary_meshes.py, build_character_rig.py) used flat Base Color only,
a real, closeable quality gap against the vehicle rather than the unreachable
blockout-vs-photorealism gap documented in Docs/KINGMAKER_XR13_ASSET_PIPELINE.md. This module
extracts and generalizes build_kingmaker.py's texture-synthesis approach (numpy noise fields
saved as PNGs, wired through Principled BSDF image-texture nodes with real roughness/metallic/
clearcoat values) so every generator script can use it, bringing them up to the same material
quality tier without pretending to close the sculpted-mesh/photoreal gap.
"""
import bpy
import math
import os

import numpy as np

_rng = np.random.default_rng(41)


def save_texture(out_dir, name, rgb_fn, size=512):
    """rgb_fn(x, y) -> (r, g, b) arrays of shape (size, size) in [0, 1]. Returns the PNG path."""
    os.makedirs(out_dir, exist_ok=True)
    xs, ys = np.meshgrid(np.linspace(0, 1, size), np.linspace(0, 1, size))
    r, g, b = rgb_fn(xs, ys)
    a = np.ones_like(r)
    pixels = np.dstack([r, g, b, a]).astype(np.float32)
    img = bpy.data.images.new(name, width=size, height=size, alpha=True)
    img.pixels = pixels.flatten()
    path = os.path.join(out_dir, name + ".png")
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    return path


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


# ---------- reusable texture generators ----------

def concrete_texture(xs, ys):
    base = 0.52
    noise = _rng.normal(0, 0.035, xs.shape)
    blotch = (_rng.random(xs.shape) < 0.04) * _rng.uniform(-0.12, -0.04, xs.shape)
    crack = np.zeros_like(xs)
    for _ in range(6):
        cx, ang, length = _rng.uniform(0, 1), _rng.uniform(0, math.pi), _rng.uniform(0.15, 0.5)
        cy = _rng.uniform(0, 1)
        dx, dy = xs - cx, ys - cy
        along = dx * math.cos(ang) + dy * math.sin(ang)
        perp = -dx * math.sin(ang) + dy * math.cos(ang)
        mask = (np.abs(along) < length) & (np.abs(perp) < 0.002)
        crack += mask * -0.15
    v = np.clip(base + noise + blotch + crack, 0.08, 0.85)
    return v, v, v


def asphalt_texture(xs, ys):
    base = 0.09
    grain = _rng.normal(0, 0.018, xs.shape)
    pebble = (_rng.random(xs.shape) < 0.08) * _rng.uniform(0.02, 0.06, xs.shape)
    v = np.clip(base + grain + pebble, 0.02, 0.4)
    return v, v, v


def wood_texture(xs, ys, tone=(0.35, 0.22, 0.12)):
    grain = np.sin(ys * 90 + np.sin(xs * 6) * 4) * 0.05
    noise = _rng.normal(0, 0.02, xs.shape)
    base = np.array(tone)
    v = base[:, None, None] + (grain + noise)[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]

def rusted_metal_texture(xs, ys):
    brushed = np.sin(xs * 380) * 0.02
    noise = _rng.normal(0, 0.03, xs.shape)
    rust = (_rng.random(xs.shape) < 0.10) * _rng.uniform(0.15, 0.4, xs.shape)
    base = 0.4 + brushed + noise
    r = np.clip(base + rust * 0.9, 0, 1)
    g = np.clip(base + rust * 0.4, 0, 1)
    b = np.clip(base + rust * 0.1, 0, 1)
    return r, g, b


def dirt_texture(xs, ys):
    base = np.array([0.30, 0.23, 0.15])
    noise = _rng.normal(0, 0.05, xs.shape)
    clump = (_rng.random(xs.shape) < 0.06) * _rng.uniform(-0.08, 0.08, xs.shape)
    v = base[:, None, None] + (noise + clump)[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]


def fabric_texture(xs, ys, tone=(0.16, 0.16, 0.19)):
    weave = (np.sin(xs * 240) * np.sin(ys * 240)) * 0.03
    noise = _rng.normal(0, 0.015, xs.shape)
    base = np.array(tone)
    v = base[:, None, None] + (weave + noise)[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]


def skin_texture(xs, ys, tone=(0.65, 0.5, 0.42)):
    mottle = _rng.normal(0, 0.02, xs.shape)
    base = np.array(tone)
    v = base[:, None, None] + mottle[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]


def plaster_texture(xs, ys, tone=(0.62, 0.58, 0.5)):
    noise = _rng.normal(0, 0.025, xs.shape)
    stain = (_rng.random(xs.shape) < 0.02) * _rng.uniform(-0.15, -0.05, xs.shape)
    base = np.array(tone)
    v = base[:, None, None] + (noise + stain)[None]
    v = np.clip(v, 0, 1)
    return v[0], v[1], v[2]
