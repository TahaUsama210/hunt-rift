"""Rewrites a monster FBX so Roblox Studio imports it at its real size in studs.

Studio ignores the FBX unit and reads the raw numbers as studs. The first exports wrote
centimetres (1 stud became 100), so monsters came in 100 times too big. This loads an
existing FBX, keeps its meshes, normals, UVs and textures, and writes it back with the
numbers in studs, without rebuilding or rebaking anything.

    python tools/roster/rescale_fbx.py Gnasher [Shardkite ...]
or  blender -b -P tools/roster/rescale_fbx.py -- Gnasher

New builds from build_roster_mesh.py already export at the right scale.
"""

import os
import sys

import bpy

EXPORT_SCALE = 0.01  # keep in step with build_roster_mesh.py


def root_width(objs):
    root = next(o for o in objs if o.name.split(".")[0] == "Root")
    xs = [(root.matrix_world @ v.co).x for v in root.data.vertices]
    return max(xs) - min(xs)


def main():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    for name in argv:
        path = os.path.join(repo, "assets", name, f"{name}.fbx")
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=path, use_custom_normals=True)
        objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        # Blender reads the old centimetre file into metres, so a 2-stud Root is 2 units wide again.
        before = root_width(objs)
        if abs(before - 2) > 0.05:
            raise SystemExit(f"{name}: Root is {before:.3f} wide after import, expected 2. Not touching it.")
        # Bake every object's transform into its mesh, like the original export.
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        for img in bpy.data.images:
            if img.source == "FILE" and not img.packed_file and img.has_data:
                img.pack()
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            object_types={"MESH"},
            global_scale=EXPORT_SCALE,
            axis_forward="-Z",
            axis_up="Y",
            apply_unit_scale=True,
            mesh_smooth_type="FACE",
            path_mode="COPY",
            embed_textures=True,
        )
        print(f"{name}: rewrote {len(objs)} meshes in studs", flush=True)


main()
