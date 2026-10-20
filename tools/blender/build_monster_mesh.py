"""Builds a Roblox-ready monster mesh from its body plan.

For every moving segment of the rig it makes a detailed high-poly sculpt (joined shapes,
scales, skin noise), a low-poly copy decimated to the segment's triangle budget (about 6,000
for the whole monster), then bakes the high-poly detail onto the low-poly as a normal map and a
color map that share one 1024x1024 atlas. Roblox caps a mesh at 20,000 triangles, so the low-poly
keeps the shape and the maps keep the detail.

Run from the project folder (Blender 4.2 or newer):
    blender -b -P tools/blender/build_monster_mesh.py -- Thornjaw
or with the bpy module:  python tools/blender/build_monster_mesh.py Thornjaw

Reads  tools/blender/<Name>.rig.json  (make it with: lune run tools/export_rig.luau <Name>)
Writes assets/<Name>/<Name>.fbx, <Name>_color.png, <Name>_normal.png, preview_*.png, report.json
"""

import json
import math
import os
import sys
import time

import bpy  # first: the bpy module sets up bmesh and mathutils
import bmesh
from mathutils import Matrix, Vector

TEXTURE_SIZE = 1024  # Roblox downsizes anything bigger to 1024.
SCALE_CELL = 0.32  # studs across one scale on the skin
SCALE_DEPTH = 0.07
FINE_SEGMENTS = {"Head", "Jaw", "Crest"}  # small teeth and spikes need a finer remesh
# Thin overlapping spikes catch their own far side when baking normals; they stay smooth.
NO_NORMAL_BAKE = {"Crest"}
DISPLACE_WEIGHT = {"skin": 1.0, "stripe": 1.0, "belly": 0.6, "crest": 0.25, "eye": 0.0, "pupil": 0.0, "bone": 0.0}


def args():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    name = argv[0] if argv else "Thornjaw"
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(here))
    return name, os.path.join(here, f"{name}.rig.json"), os.path.join(root, "assets", name)


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


def build_base(seg, prims):
    """Joins the segment's shapes into one smooth closed surface."""
    objs = [make_shape_object(f"{seg['name']}_{i}", p) for i, p in enumerate(prims)]
    select_only(*objs, active=objs[0])
    bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    base.name = seg["name"] + "_base"
    remesh = base.modifiers.new("remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = 0.035 if seg["name"] in FINE_SEGMENTS or "LowerLeg" in seg["name"] else 0.06
    smooth = base.modifiers.new("smooth", "CORRECTIVE_SMOOTH")
    smooth.iterations = 4
    smooth.use_only_smooth = True
    apply_modifiers(base)
    return base


def paint(base, prims, colors):
    """Colors each vertex by the shape it sits on; later shapes (details) win over the body."""
    mats = [roblox_matrix(p["pos"], p.get("rot"), p["size"]).inverted() for p in prims]
    mesh = base.data
    attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    groups = {key: base.vertex_groups.new(name=key) for key in DISPLACE_WEIGHT}
    weight = base.vertex_groups.new(name="displace")
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
        attr.data[v.index].color = (srgb(r), srgb(g), srgb(b), 1)
        groups[key].add([v.index], 1.0, "REPLACE")
        weight.add([v.index], DISPLACE_WEIGHT.get(key, 1.0), "REPLACE")


def srgb(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def make_high(base):
    """The detailed sculpt: scales and skin noise pushed into the surface."""
    high = base.copy()
    high.data = base.data.copy()
    high.name = base.name.replace("_base", "_high")
    bpy.context.collection.objects.link(high)

    scales = bpy.data.textures.get("scales") or bpy.data.textures.new("scales", "VORONOI")
    scales.noise_scale = SCALE_CELL
    scales.distance_metric = "DISTANCE"
    disp = high.modifiers.new("scales", "DISPLACE")
    disp.texture = scales
    disp.texture_coords = "GLOBAL"
    disp.strength = -SCALE_DEPTH
    disp.mid_level = 0.3
    disp.vertex_group = "displace"

    noise = bpy.data.textures.get("skin") or bpy.data.textures.new("skin", "CLOUDS")
    noise.noise_scale = 0.6
    disp2 = high.modifiers.new("skin", "DISPLACE")
    disp2.texture = noise
    disp2.texture_coords = "GLOBAL"
    disp2.strength = 0.05
    disp2.vertex_group = "displace"

    high.data.materials.append(high_material())
    return high


def high_material():
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
    links.new(mul.outputs["Result"], bsdf.inputs["Base Color"])
    return mat


def make_low(base, target_tris):
    low = base.copy()
    low.data = base.data.copy()
    low.name = base.name.replace("_base", "")
    low.vertex_groups.clear()
    bpy.context.collection.objects.link(low)
    dec = low.modifiers.new("decimate", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = min(1.0, target_tris / max(1, tri_count(low)))
    dec.use_symmetry = True
    dec.symmetry_axis = "X"
    tri = low.modifiers.new("tri", "TRIANGULATE")
    apply_modifiers(low)
    for a in list(low.data.color_attributes):
        low.data.color_attributes.remove(a)
    # Smooth skin, but crisp edges on spikes, teeth and claws.
    select_only(low)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(50))
    return low


def unwrap(lows):
    select_only(*lows)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.006, area_weight=0.0)
    bpy.ops.object.mode_set(mode="OBJECT")


def new_image(name, color, non_color):
    img = bpy.data.images.new(name, TEXTURE_SIZE, TEXTURE_SIZE, alpha=False, float_buffer=False)
    img.generated_color = color
    if non_color:
        img.colorspace_settings.name = "Non-Color"
    return img


def low_material(color_img, normal_img):
    mat = bpy.data.materials.new("MonsterSkin")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.65
    ctex = nodes.new("ShaderNodeTexImage")
    ctex.image = color_img
    ntex = nodes.new("ShaderNodeTexImage")
    ntex.image = normal_img
    nmap = nodes.new("ShaderNodeNormalMap")
    links.new(ctex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    return mat, ctex, ntex


def bake(pairs, mat, node, image, kind):
    scene = bpy.context.scene
    mat.node_tree.nodes.active = node
    node.image = image
    bake_settings = scene.render.bake
    bake_settings.use_selected_to_active = True
    bake_settings.margin = 6
    bake_settings.use_clear = False
    for high, low in pairs:
        # Thin spikes and teeth need short rays, or they catch the far side of themselves.
        fine = low.name in FINE_SEGMENTS
        bake_settings.cage_extrusion = 0.07 if fine else 0.12
        bake_settings.max_ray_distance = 0.3 if fine else 0.5
        if kind == "NORMAL" and low.name in NO_NORMAL_BAKE:
            continue
        select_only(high, low, active=low)
        if kind == "NORMAL":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
        else:
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"})


def render_preview(lows, root, path):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        o.hide_render = o not in lows
    # A 5-stud figure for scale, about the size of a Roblox character.
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=5, location=(-6, 8, 2.5))
    person = bpy.context.object
    pm = bpy.data.materials.new("Person")
    pm.diffuse_color = (0.8, 0.8, 0.8, 1)
    person.data.materials.append(pm)
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0))
    ground = bpy.context.object
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.35, 0.36, 0.38, 1)
    ground.data.materials.append(gm)
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), math.radians(10), math.radians(-40)))
    bpy.context.object.data.energy = 3.5
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.7, 0.9, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = world
    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.data.lens = 40
    scene.camera = cam
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    target = Vector((0, -1.5, 4.5))
    for suffix, location in (("front", (-20, 24, 11)), ("side", (-34, 0, 7))):
        cam.location = location
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = path.replace(".png", f"_{suffix}.png")
        try:
            bpy.ops.render.render(write_still=True)
        except RuntimeError:
            scene.cycles.use_denoising = False
            scene.cycles.samples = 128
            bpy.ops.render.render(write_still=True)


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
    for seg in rig["segments"]:
        prims = [seg] + [d for d in rig["details"] if d["segment"] == seg["name"]]
        base = build_base(seg, prims)
        paint(base, prims, rig["colors"])
        high = make_high(base)
        low = make_low(base, seg["tris"])
        bpy.data.objects.remove(base)
        pairs.append((high, low))
        lows.append(low)
        report["segments"][seg["name"]] = {"tris": tri_count(low), "highTris": tri_count(high)}
        report["totalTris"] += tri_count(low)
        print(f"{seg['name']}: high {tri_count(high)} -> low {tri_count(low)} tris", flush=True)

    unwrap(lows)
    color_img = new_image(f"{name}_color", (0.2, 0.4, 0.37, 1), False)
    normal_img = new_image(f"{name}_normal", (0.5, 0.5, 1, 1), True)
    mat, ctex, ntex = low_material(color_img, normal_img)
    for low in lows:
        low.data.materials.append(mat)
    bake(pairs, mat, ntex, normal_img, "NORMAL")
    bake(pairs, mat, ctex, color_img, "DIFFUSE")
    ntex.image, ctex.image = normal_img, color_img
    for img in (color_img, normal_img):
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
    render_preview(lows, root, os.path.join(out_dir, "preview.png"))

    report["seconds"] = round(time.time() - started)
    with open(os.path.join(out_dir, "report.json"), "w") as f:
        json.dump(report, f, indent=2)
    print(f"Total {report['totalTris']} tris. Wrote {out_dir}", flush=True)


main()
