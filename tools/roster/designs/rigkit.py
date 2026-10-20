"""Helpers for writing monster body plans (rig.json) in the same format as the game's
Rigs/GreatJagras.luau, so tools/build_roster_mesh.py and the game can read them.

Space: studs, the monster faces -Z, feet on y = 0. rot is degrees applied like
CFrame.Angles(x, y, z): x = nose up, y = turn left, z = roll.
Shapes: "ellipsoid", "block", "wedge" (full bottom, vertical back face at +z, slope to -z).
"""

import json
import math
import os


def along(p0, p1, w, h=None, roll=0.0, overshoot=1.0):
    """Shape fields for an ellipsoid stretched from p0 to p1 (width w, height h)."""
    d = [b - a for a, b in zip(p0, p1)]
    length = math.sqrt(sum(c * c for c in d)) or 1e-6
    dx, dy, dz = (c / length for c in d)
    ry = math.asin(max(-1.0, min(1.0, dx)))
    rx = math.atan2(-dy, dz)
    return {
        "shape": "ellipsoid",
        "pos": [round((a + b) / 2, 4) for a, b in zip(p0, p1)],
        "size": [w, h if h is not None else w, round(length * overshoot, 4)],
        "rot": [round(math.degrees(rx), 3), round(math.degrees(ry), 3), roll],
    }


def spike(base, tip, w, h=None, roll=0.0):
    """A horn, claw or spine: an ellipsoid whose visible half runs from base to tip."""
    inner = [b - (t - b) for b, t in zip(base, tip)]
    return along(inner, tip, w, h, roll)


def mirror(v, side):
    return [v[0] * side, v[1], v[2]]


def mrot(rot, side):
    """Mirror a rotation across the x = 0 plane."""
    if rot is None:
        return None
    return [rot[0], rot[1] * side, rot[2] * side]


class Rig:
    def __init__(self, name, display, colors, hip_height, glow=(), displace=None, skin=None, notes=""):
        self.data = {
            "name": name,
            "displayName": display,
            "colors": colors,
            "glow": {c: True for c in glow},
            # How much the skin texture pushes into each color (0 = smooth, eyes and gems).
            "displace": displace or {},
            # Size of the skin pattern: cell = studs across one scale or plate.
            "skin": skin or {"cell": 0.32, "depth": 0.07, "noise": 0.05, "pattern": "VORONOI"},
            "hipHeight": hip_height,
            "rootSize": [2, 2, 2],
            "segments": [],
            "details": [],
            "notes": notes,
        }

    def seg(self, name, attach, joint, joint_at, shape, color, hitzone, tris, **extra):
        s = {
            "name": name,
            "attach": attach,
            "joint": joint,
            "jointAt": list(joint_at),
            "color": color,
            "hitzone": hitzone,
            "tris": tris,
        }
        s.update(shape)
        s.update(extra)  # fine, voxel, smoothBake, breaksWith
        self.data["segments"].append(s)
        return s

    def det(self, segment, shape, color, side=1):
        d = {"segment": segment, "color": color}
        d.update(shape)
        if side != 1:
            d["pos"] = mirror(d["pos"], side)
            d["rot"] = mrot(d.get("rot"), side)
        self.data["details"].append(d)
        return d

    def shape(self, kind, size, pos, rot=None):
        s = {"shape": kind, "size": list(size), "pos": list(pos)}
        if rot:
            s["rot"] = list(rot)
        return s

    def save(self, folder):
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, self.data["name"] + ".rig.json")
        with open(path, "w") as f:
            json.dump(self.data, f, indent=1)
        total = sum(s["tris"] for s in self.data["segments"])
        print(f"{self.data['name']}: {len(self.data['segments'])} segments, "
              f"{len(self.data['details'])} details, {total} tri budget -> {path}")
        return path


def mseg(rig, name, side, attach, joint, joint_at, shape, color, hitzone, tris, **extra):
    """A segment on one side: name gets L/R, positions mirror for side -1."""
    tag = "R" if side == 1 else "L"
    s = dict(shape)
    s["pos"] = mirror(s["pos"], side)
    s["rot"] = mrot(s.get("rot"), side)
    if s["rot"] is None:
        s.pop("rot")
    return rig.seg(name + tag, attach if attach in ("Root",) or not attach.endswith("@") else attach[:-1] + tag,
                   joint + tag, mirror(joint_at, side), s, color, hitzone, tris, **extra)
