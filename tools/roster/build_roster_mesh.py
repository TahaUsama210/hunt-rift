"""Builds a Roblox-ready monster mesh from its body plan (roster version).

Adapted from roblox-game/tools/blender/build_monster_mesh.py (the Great Jagras pipeline):
same rig.json format, same steps, but every monster-specific setting now comes from the rig
so one script builds the whole roster.

For every moving segment it makes a detailed high-poly sculpt (joined shapes, scales or
plates, skin noise), a low-poly copy decimated to the segment's triangle budget (about 6,000
for the whole monster; Roblox caps one mesh at 20,000), then bakes the high-poly detail onto
the low-poly as a normal map, a color map and a glow mask that share one 1024x1024 atlas.
The low-poly keeps the silhouette and the maps keep the detail.

Run from the repo root (Blender 4.2 or newer):
    python tools/roster/designs/shardkite.py          (writes tools/roster/rigs/Shardkite.rig.json)
    blender -b -P tools/roster/build_roster_mesh.py -- Shardkite
or with the bpy module:  python tools/roster/build_roster_mesh.py Shardkite [--quick]

Writes assets/<Name>/<Name>.fbx, <Name>_color.png, <Name>_normal.png, <Name>_glow.png,
       preview_*.png, report.json

The camp NPCs go through the same script: tools/roster/designs/npcs.py turns their body plans
(src/shared/Rigs, exported by tools/export_rig.luau) into rigs here, adding sculpt-only detail
and per-color surface styles (hair strands, fur, cloth, leather, wood, hammered metal).
"""

import json
import math
import os
import sys
import time

import bpy  # first: the bpy module sets up bmesh and mathutils
import bmesh
from mathutils import Matrix, Vector

QUICK = False  # --quick: shapes and colors only, a fast look while designing
TEXTURE_SIZE = 1024  # Roblox downsizes anything bigger to 1024.
PREVIEW_SAMPLES = int(os.environ.get("PREVIEW_SAMPLES", "48"))


# Surface styles (rig "styles": color -> style). Each layer is (texture, settings, strength,
# strands): strands is the spacing in studs of a pattern that runs downwards like hair or wood
# grain, or None for a pattern that goes every way.
STYLES = {
    "hair": [
        ("WOOD", {"wood_type": "BANDNOISE", "noise_basis_2": "SIN", "turbulence": 5.0, "noise_scale": 0.35}, 0.06, 0.17),
        ("CLOUDS", {"noise_scale": 0.45}, 0.05, None),
    ],
    "fur": [
        ("VORONOI", {"noise_scale": 0.16}, -0.1, None),
        ("CLOUDS", {"noise_scale": 0.3}, 0.07, None),
    ],
    "cloth": [
        ("CLOUDS", {"noise_scale": 0.8, "noise_depth": 1}, 0.08, None),
        ("STUCCI", {"noise_scale": 0.06}, 0.012, None),
    ],
    "leather": [
        ("STUCCI", {"noise_scale": 0.09, "turbulence": 3.0}, 0.018, None),
        ("CLOUDS", {"noise_scale": 0.5}, 0.035, None),
    ],
    "wood": [
        ("WOOD", {"wood_type": "BANDNOISE", "noise_basis_2": "SIN", "turbulence": 8.0, "noise_scale": 0.25}, 0.035, 0.3),
    ],
    "metal": [
        ("CLOUDS", {"noise_scale": 0.22, "noise_type": "HARD_NOISE"}, 0.014, None),
    ],
}


def args():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    global QUICK
    QUICK = "--quick" in argv
    argv = [a for a in argv if a != "--quick"]
    name = argv[0] if argv else "Shardkite"
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.dirname(os.path.dirname(here))
    return name, os.path.join(here, "rigs", f"{name}.rig.json"), os.path.join(repo, "assets", name)


# Roblox space (x right, y up, -z forward) to Blender space (x right, z up, -y forward).
TO_BLENDER = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def roblox_matrix(pos, rot, size):
    rx, ry, rz = (math.radians(a) for a in (rot or (0, 0, 0)))
    # Same order as CFrame.Angles(rx, ry, rz).
    r = Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z")
    s = Matrix.Diagonal((size[0] / 2, size[1] / 2, size[2] / 2, 1))
    return TO_BLENDER @ Matrix.Translation(pos) @ r @ s


def unit_shape(shape, bm):
    """Adds a unit shape (half-size 1) in Roblox local space to bm."""
    if shape == "ellipsoid":
        bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=1)
    elif shape == "block":
        bmesh.ops.create_cube(bm, size=2)
    elif shape == "wedge":
        # Roblox wedge: full bottom, vertical back face (+z), slope down to the front (-z).
        pts = [(-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1), (-1, 1, 1), (1, 1, 1)]
        v = [bm.verts.new(p) for p in pts]
        for face in ((0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)):
            bm.faces.new([v[i] for i in face])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


def inside(shape, local):
    """How far inside a unit shape a local point is: <= 1 means inside or on the surface."""
    x, y, z = abs(local.x), local.y, local.z
    if shape == "ellipsoid":
        return local.length
    box = max(x, abs(y), abs(z))
    if shape == "wedge":
        return max(box, 1 + (y + 1) / 2 - (z + 1) / 2)
    return box


def make_shape_object(name, prim):
    bm = bmesh.new()
    unit_shape(prim["shape"], bm)
    bm.transform(roblox_matrix(prim["pos"], prim.get("rot"), prim["size"]))
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def select_only(*objs, active=None):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def apply_modifiers(obj):
    select_only(obj)
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def voxel_for(seg):
    """Voxel size for the remesh: explicit, or from the segment's size (finer for small parts)."""
    if "voxel" in seg:
        return seg["voxel"]
    biggest = max(seg["size"])
    v = biggest / (220 if seg.get("fine") else 150)
    return max(0.03, min(0.1, v))


def build_base(seg, prims):
    """Joins the segment's shapes into one smooth closed surface."""
    objs = [make_shape_object(f"{seg['name']}_{i}", p) for i, p in enumerate(prims)]
    select_only(*objs, active=objs[0])
    bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    base.name = seg["name"] + "_base"
    remesh = base.modifiers.new("remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel_for(seg)
    smooth = base.modifiers.new("smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 4
    smooth.use_only_smooth = True
    apply_modifiers(base)
    return base


def paint(base, prims, rig):
    """Colors each vertex by the shape it sits on; later shapes (details) win over the body."""
    colors, glow, displace = rig["colors"], rig.get("glow", {}), rig.get("displace", {})
    styles = rig.get("styles", {})
    mats = [roblox_matrix(p["pos"], p.get("rot"), p["size"]).inverted() for p in prims]
    mesh = base.data
    cols, glows, weights, styled = [], [], [], {}
    for v in mesh.vertices:
        best, best_f = 0, 1e9
        for i, (p, m) in enumerate(zip(prims, mats)):
            f = inside(p["shape"], m @ v.co)
            if f <= 1.06:
                best, best_f = i, f  # last match wins: details paint over the body
            elif best_f > 1.06 and f < best_f:
                best, best_f = i, f
        key = prims[best]["color"]
        r, g, b = colors[key]
        cols += (srgb(r), srgb(g), srgb(b), 1)
        lit = 1.0 if glow.get(key) else 0.0
        glows += (lit, lit, lit, 1)
        weights.append(displace.get(key, 0.0 if glow.get(key) else 1.0))
        if key in styles:
            styled.setdefault(styles[key], []).append(v.index)
    # Write everything after the loop: adding attributes or groups moves mesh data in memory.
    mesh.color_attributes.new("Col", "FLOAT_COLOR", "POINT").data.foreach_set("color", cols)
    mesh.color_attributes.new("Glow", "FLOAT_COLOR", "POINT").data.foreach_set("color", glows)
    group = base.vertex_groups.new(name="displace")
    by_weight = {}
    for i, w in enumerate(weights):
        by_weight.setdefault(w, []).append(i)
    for w, idx in by_weight.items():
        group.add(idx, w, "REPLACE")
    for style, idx in styled.items():
        base.vertex_groups.new(name="style_" + style).add(idx, 1.0, "REPLACE")


def srgb(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def strands_object(spacing):
    """An empty whose space stretches the texture along z, so bands run downwards."""
    name = f"strands_{spacing}"
    empty = bpy.data.objects.get(name)
    if not empty:
        empty = bpy.data.objects.new(name, None)
        bpy.context.collection.objects.link(empty)
        # Wood bands repeat every 2*pi/10 texture units; scale that to the spacing in studs.
        s = spacing / (2 * math.pi / 10)
        empty.scale = (s, s, 40)
    return empty


def add_styles(high):
    """Hair strands, fur, cloth folds, leather grain, wood grain and hammered metal."""
    for group in high.vertex_groups:
        if not group.name.startswith("style_"):
            continue
        style = group.name[len("style_"):]
        for i, (kind, settings, strength, strands) in enumerate(STYLES[style]):
            name = f"{style}_{i}"
            tex = bpy.data.textures.get(name)
            if not tex:
                tex = bpy.data.textures.new(name, kind)
                for key, value in settings.items():
                    setattr(tex, key, value)
            disp = high.modifiers.new(name, "DISPLACE")
            disp.texture = tex
            disp.strength = strength
            disp.vertex_group = group.name
            if strands:
                disp.texture_coords = "OBJECT"
                disp.texture_coords_object = strands_object(strands)
            else:
                disp.texture_coords = "GLOBAL"


def make_high(base, skin, rig=None):
    """The detailed sculpt: scales or plates and skin noise pushed into the surface."""
    high = base.copy()
    high.data = base.data.copy()
    high.name = base.name.replace("_base", "_high")
    bpy.context.collection.objects.link(high)
    if rig and rig.get("styles"):
        add_styles(high)

    scales = bpy.data.textures.get("scales")
    if not scales:
        scales = bpy.data.textures.new("scales", "VORONOI")
        scales.noise_scale = skin["cell"]
        scales.distance_metric = skin.get("metric", "DISTANCE")
    disp = high.modifiers.new("scales", "DISPLACE")
    disp.texture = scales
    disp.texture_coords = "GLOBAL"
    disp.strength = -skin["depth"]
    disp.mid_level = 0.3
    disp.vertex_group = "displace"

    noise = bpy.data.textures.get("skin")
    if not noise:
        noise = bpy.data.textures.new("skin", "CLOUDS")
        noise.noise_scale = skin.get("noiseScale", 0.6)
    disp2 = high.modifiers.new("skin", "DISPLACE")
    disp2.texture = noise
    disp2.texture_coords = "GLOBAL"
    disp2.strength = skin["noise"]
    disp2.vertex_group = "displace"

    high.data.materials.append(high_material(rig or {}))
    return high


def high_material(rig):
    mat = bpy.data.materials.get("HighBake")
    if mat:
        return mat
    mat = bpy.data.materials.new("HighBake")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    col = nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    # Crevices between scales read darker, so the baked colors keep the detail too.
    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.samples = 16
    ao.inputs["Distance"].default_value = 0.2
    ramp = nodes.new("ShaderNodeMapRange")
    ramp.inputs["To Min"].default_value = 0.45
    links.new(ao.outputs["AO"], ramp.inputs["Value"])
    mul = nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1
    links.new(col.outputs["Color"], mul.inputs["A"])
    links.new(ramp.outputs["Result"], mul.inputs["B"])
    shaded = mul.outputs["Result"]
    if rig.get("paintLight"):
        # Painted-on light for the stylised characters: tops a little brighter, undersides a
        # little darker, and raised edges catch a highlight, so they read well from any side.
        geo = nodes.new("ShaderNodeNewGeometry")
        sep = nodes.new("ShaderNodeSeparateXYZ")
        links.new(geo.outputs["Normal"], sep.inputs["Vector"])
        top = nodes.new("ShaderNodeMapRange")
        top.inputs["From Min"].default_value = -1
        top.inputs["To Min"].default_value = 0.8
        top.inputs["To Max"].default_value = 1.1
        links.new(sep.outputs["Z"], top.inputs["Value"])
        edge = nodes.new("ShaderNodeMapRange")
        edge.inputs["From Min"].default_value = 0.5
        edge.inputs["From Max"].default_value = 0.6
        edge.inputs["To Min"].default_value = 1.0
        edge.inputs["To Max"].default_value = 1.18
        links.new(geo.outputs["Pointiness"], edge.inputs["Value"])
        for factor in (top, edge):
            m = nodes.new("ShaderNodeMix")
            m.data_type = "RGBA"
            m.blend_type = "MULTIPLY"
            m.inputs["Factor"].default_value = 1
            links.new(shaded, m.inputs["A"])
            links.new(factor.outputs["Result"], m.inputs["B"])
            shaded = m.outputs["Result"]
    # Glowing parts keep their full color: no crevice shading, so bloom picks them up.
    glow = nodes.new("ShaderNodeVertexColor")
    glow.layer_name = "Glow"
    keep = nodes.new("ShaderNodeMix")
    keep.data_type = "RGBA"
    links.new(glow.outputs["Color"], keep.inputs["Factor"])
    links.new(shaded, keep.inputs["A"])
    links.new(col.outputs["Color"], keep.inputs["B"])
    links.new(keep.outputs["Result"], bsdf.inputs["Base Color"])
    return mat


def glow_bake_material():
    """Emits the Glow vertex color, so an EMIT bake turns it into a black/white mask."""
    mat = bpy.data.materials.new("GlowBake")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    col = nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Glow"
    links.new(col.outputs["Color"], em.inputs["Color"])
    links.new(em.outputs["Emission"], out.inputs["Surface"])
    return mat


def is_centered(obj):
    xs = [v.co.x for v in obj.data.vertices]
    return abs(min(xs) + max(xs)) < 0.2


def make_low(base, target_tris, smooth_angle=50):
    low = base.copy()
    low.data = base.data.copy()
    low.name = base.name.replace("_base", "")
    low.vertex_groups.clear()
    bpy.context.collection.objects.link(low)
    dec = low.modifiers.new("decimate", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = min(1.0, target_tris / max(1, tri_count(low)))
    # Symmetric decimation only for pieces on the middle line (side pieces have no mirror).
    dec.use_symmetry = is_centered(low)
    dec.symmetry_axis = "X"
    low.modifiers.new("tri", "TRIANGULATE")
    apply_modifiers(low)
    for attr_name in [a.name for a in low.data.color_attributes]:
        low.data.color_attributes.remove(low.data.color_attributes[attr_name])
    # Smooth skin, but crisp edges on spikes, teeth and claws (and on blocky parts, where a
    # lower rig "smoothAngle" keeps flat faces flat so the bake rays go straight).
    select_only(low)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(smooth_angle))
    return low


def unwrap(lows, boost=None):
    select_only(*lows)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.006, area_weight=0.0)
    bpy.ops.object.mode_set(mode="OBJECT")
    if not boost:
        return
    # Give faces more of the atlas (rig "uvBoost": segment -> scale), then pack again.
    for low in lows:
        factor = boost.get(low.name)
        if factor:
            for loop_uv in low.data.uv_layers.active.data:
                loop_uv.uv = loop_uv.uv * factor
    select_only(*lows)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=0.006)
    bpy.ops.object.mode_set(mode="OBJECT")


def new_image(name, color, non_color):
    img = bpy.data.images.new(name, TEXTURE_SIZE, TEXTURE_SIZE, alpha=False, float_buffer=False)
    img.generated_color = color
    if non_color:
        img.colorspace_settings.name = "Non-Color"
    return img


def low_material(color_img, normal_img, glow_img):
    mat = bpy.data.materials.new("MonsterSkin")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.6
    ctex = nodes.new("ShaderNodeTexImage")
    ctex.image = color_img
    ntex = nodes.new("ShaderNodeTexImage")
    ntex.image = normal_img
    gtex = nodes.new("ShaderNodeTexImage")
    gtex.image = glow_img
    nmap = nodes.new("ShaderNodeNormalMap")
    links.new(ctex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    # Preview only: glowing parts emit their own color (in Roblox: an emissive or Neon overlay).
    links.new(ctex.outputs["Color"], bsdf.inputs["Emission Color"])
    links.new(gtex.outputs["Color"], bsdf.inputs["Emission Strength"])
    return mat, ctex, ntex, gtex


def bake(pairs, mat, node, image, kind, segs):
    scene = bpy.context.scene
    mat.node_tree.nodes.active = node
    node.image = image
    bake_settings = scene.render.bake
    bake_settings.use_selected_to_active = True
    bake_settings.margin = 6
    bake_settings.use_clear = False
    for high, low in pairs:
        seg = segs[low.name]
        # Thin spikes and teeth need short rays, or they catch the far side of themselves.
        fine = seg.get("fine")
        bake_settings.cage_extrusion = 0.07 if fine else 0.12
        bake_settings.max_ray_distance = 0.3 if fine else 0.5
        if kind == "NORMAL" and seg.get("smoothBake"):
            continue
        select_only(high, low, active=low)
        if kind == "NORMAL":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
        elif kind == "EMIT":
            bpy.ops.object.bake(type="EMIT")
        else:
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"})


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def render_preview(lows, out_dir, sky, prefix="preview"):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        o.hide_render = o not in lows
    lo, hi = bounds(lows)
    center = (lo + hi) / 2
    extent = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    # A 5-stud figure for scale, about the size of a Roblox character, behind the far flank.
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=5, location=(hi.x + 2.5, lo.y + 1.5, 2.5))
    person = bpy.context.object
    pm = bpy.data.materials.new("Person")
    pm.diffuse_color = (0.8, 0.8, 0.8, 1)
    person.data.materials.append(pm)
    bpy.ops.mesh.primitive_plane_add(size=extent * 8, location=(center.x, center.y, 0))
    ground = bpy.context.object
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.35, 0.36, 0.38, 1)
    ground.data.materials.append(gm)
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), math.radians(10), math.radians(-40)))
    bpy.context.object.data.energy = 3.5
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (*sky, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = world
    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.data.lens = 40
    scene.camera = cam
    scene.cycles.samples = PREVIEW_SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    target = center.copy()
    dist = extent * 1.45 + 6
    # Blender space: the monster faces +y. Front three-quarter, side, and high back view.
    views = {
        "front": Vector((-0.55, 0.75, 0.32)),
        "side": Vector((-1.0, 0.0, 0.15)),
        "back": Vector((0.6, -0.65, 0.55)),
    }
    for suffix, direction in views.items():
        cam.location = target + direction.normalized() * dist
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(out_dir, f"{prefix}_{suffix}.png")
        try:
            bpy.ops.render.render(write_still=True)
        except RuntimeError:
            scene.cycles.use_denoising = False
            scene.cycles.samples = PREVIEW_SAMPLES * 3
            bpy.ops.render.render(write_still=True)


def quick_preview(rig, out_dir):
    """Joined shapes with flat colors and few samples: a fast look while designing."""
    bases = []
    for seg in rig["segments"]:
        prims = [seg] + [d for d in rig["details"] if d["segment"] == seg["name"]]
        seg = dict(seg, voxel=max(voxel_for(seg), 0.07))
        base = build_base(seg, prims)
        paint(base, prims, rig)
        bases.append(base)
    mat = bpy.data.materials.new("Quick")
    mat.use_nodes = True
    col = mat.node_tree.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    mat.node_tree.links.new(col.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    for base in bases:
        base.data.materials.append(mat)
    global PREVIEW_SAMPLES
    PREVIEW_SAMPLES = 12
    bpy.context.scene.render.resolution_percentage = 50
    render_preview(bases, out_dir, rig.get("sky", (0.55, 0.7, 0.9)), prefix="quick")


def main():
    name, rig_path, out_dir = args()
    os.makedirs(out_dir, exist_ok=True)
    with open(rig_path) as f:
        rig = json.load(f)
    started = time.time()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        import addon_utils

        addon_utils.enable("cycles", default_set=True)
    except Exception:
        pass
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4

    report = {"segments": {}, "totalTris": 0}
    pairs, lows = [], []
    segs = {s["name"]: s for s in rig["segments"]}
    if QUICK:
        quick_preview(rig, out_dir)
        return
    for seg in rig["segments"]:
        prims = [seg] + [d for d in rig["details"] if d["segment"] == seg["name"]]
        base = build_base(seg, prims)
        paint(base, prims, rig)
        high = make_high(base, rig["skin"], rig)
        low = make_low(base, seg["tris"], seg.get("smoothAngle", rig.get("smoothAngle", 50)))
        bpy.data.objects.remove(base)
        pairs.append((high, low))
        lows.append(low)
        report["segments"][seg["name"]] = {"tris": tri_count(low), "highTris": tri_count(high)}
        report["totalTris"] += tri_count(low)
        print(f"{seg['name']}: high {tri_count(high)} -> low {tri_count(low)} tris", flush=True)
    report["highTris"] = sum(v["highTris"] for v in report["segments"].values())

    unwrap(lows, rig.get("uvBoost"))
    base_rgb = [srgb(c) for c in rig["colors"][rig["segments"][0]["color"]]]
    color_img = new_image(f"{name}_color", (*base_rgb, 1), False)
    normal_img = new_image(f"{name}_normal", (0.5, 0.5, 1, 1), True)
    glow_img = new_image(f"{name}_glow", (0, 0, 0, 1), True)
    mat, ctex, ntex, gtex = low_material(color_img, normal_img, glow_img)
    for low in lows:
        low.data.materials.append(mat)
    bake(pairs, mat, ntex, normal_img, "NORMAL", segs)
    bake(pairs, mat, ctex, color_img, "DIFFUSE", segs)
    if rig.get("glow"):
        gmat = glow_bake_material()
        for high, _ in pairs:
            high.data.materials[0] = gmat
        bake(pairs, mat, gtex, glow_img, "EMIT", segs)
    ntex.image, ctex.image, gtex.image = normal_img, color_img, glow_img
    images = [color_img, normal_img] + ([glow_img] if rig.get("glow") else [])
    for img in images:
        img.filepath_raw = os.path.join(out_dir, img.name + ".png")
        img.file_format = "PNG"
        img.save()

    # A 2-stud cube where the rig's root joint is, so the game can line the pieces up.
    bm = bmesh.new()
    unit_shape("block", bm)
    bm.transform(roblox_matrix((0, rig["hipHeight"], 0), None, rig["rootSize"]))
    root_mesh = bpy.data.meshes.new("Root")
    bm.to_mesh(root_mesh)
    bm.free()
    root = bpy.data.objects.new("Root", root_mesh)
    bpy.context.collection.objects.link(root)

    for high, _ in pairs:
        high.hide_render = True
    select_only(*lows, root)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(out_dir, f"{name}.fbx"),
        use_selection=True,
        object_types={"MESH"},
        # Studio reads the raw numbers as studs and ignores the FBX unit, so write studs, not
        # Blender's centimetres (1 stud would import as 100).
        global_scale=0.01,
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )
    for high, _ in pairs:
        bpy.data.objects.remove(high)
    bpy.data.objects.remove(root)
    render_preview(lows, out_dir, rig.get("sky", (0.55, 0.7, 0.9)))

    report["seconds"] = round(time.time() - started)
    with open(os.path.join(out_dir, "report.json"), "w") as f:
        json.dump(report, f, indent=2)
    print(f"Total {report['totalTris']} tris (high {report['highTris']}). Wrote {out_dir}", flush=True)


main()
