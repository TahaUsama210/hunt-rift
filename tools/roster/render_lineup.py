"""Renders built characters side by side from their exported FBX files and baked maps, the way
they come out of the pipeline, to check them together (sizes, colors, silhouettes).

    python tools/roster/render_lineup.py out.png Ama Pell Odra Wren Brannoc

Each model is scaled so its Root cube matches the rig's rootSize, then the Root is hidden.
"""

import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
SPACING = 9.0


def material(name, folder):
    mat = bpy.data.materials.new(name + "Skin")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.65
    col = nodes.new("ShaderNodeTexImage")
    col.image = bpy.data.images.load(os.path.join(folder, f"{name}_color.png"))
    nor = nodes.new("ShaderNodeTexImage")
    nor.image = bpy.data.images.load(os.path.join(folder, f"{name}_normal.png"))
    nor.image.colorspace_settings.name = "Non-Color"
    nmap = nodes.new("ShaderNodeNormalMap")
    links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(nor.outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    glow_path = os.path.join(folder, f"{name}_glow.png")
    if os.path.exists(glow_path):
        glow = nodes.new("ShaderNodeTexImage")
        glow.image = bpy.data.images.load(glow_path)
        glow.image.colorspace_settings.name = "Non-Color"
        boost = nodes.new("ShaderNodeMath")
        boost.operation = "MULTIPLY"
        boost.inputs[1].default_value = 4.0
        links.new(glow.outputs["Color"], boost.inputs[0])
        links.new(col.outputs["Color"], bsdf.inputs["Emission Color"])
        links.new(boost.outputs["Value"], bsdf.inputs["Emission Strength"])
    return mat


def place(name, x):
    folder = os.path.join(REPO, "assets", name)
    with open(os.path.join(HERE, "rigs", f"{name}.rig.json")) as f:
        rig = json.load(f)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(folder, f"{name}.fbx"), axis_forward="-Z", axis_up="Y")
    objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    root = next(o for o in objs if o.name.split(".")[0] == "Root")
    xs = [(root.matrix_world @ v.co).x for v in root.data.vertices]
    scale = rig["rootSize"][0] / (max(xs) - min(xs))
    mat = material(name, folder)
    for o in objs:
        o.data.materials.clear()
        o.data.materials.append(mat)
        o.matrix_world = Matrix.Translation((x, 0, 0)) @ Matrix.Scale(scale, 4) @ o.matrix_world
    root.hide_render = True
    return objs


def main():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    out, names = argv[0], argv[1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = int(os.environ.get("SAMPLES", "64"))
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1600, 760
    width = SPACING * (len(names) - 1)
    for i, name in enumerate(names):
        # The camera looks back down -y, so the first name lands on the left of the picture.
        place(name, width / 2 - i * SPACING)

    bpy.ops.mesh.primitive_plane_add(size=2000, location=(0, 0, 0))
    ground = bpy.context.object
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.055, 0.08, 1)
    ground.data.materials.append(gm)
    world = bpy.data.worlds.new("Night")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.03, 0.035, 0.06, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    scene.world = world
    # Warm key from the front left, cool rim from behind.
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(55), 0, math.radians(-150)))
    bpy.context.object.data.energy = 3.0
    bpy.context.object.data.color = (1.0, 0.92, 0.82)
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(60), 0, math.radians(20)))
    bpy.context.object.data.energy = 2.0
    bpy.context.object.data.color = (0.6, 0.7, 1.0)
    bpy.ops.object.light_add(type="AREA", location=(0, 20, 14))
    bpy.context.object.data.energy = 2500
    bpy.context.object.data.size = 20
    bpy.context.object.rotation_euler = (Vector((0, 0, 4)) - Vector((0, 20, 14))).to_track_quat("-Z", "Y").to_euler()

    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.data.lens = 50
    scene.camera = cam
    view = os.environ.get("VIEW", "front")
    target = Vector((0, 0, 4.2))
    direction = Vector((0, 1, 0.18)) if view == "front" else Vector((-0.55, 1, 0.3))
    cam.location = target + direction.normalized() * (width * 1.4 + 16)
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)


main()
