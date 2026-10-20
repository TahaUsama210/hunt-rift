"""Mesh rigs for the Rift Camp NPCs: Brannoc, Wren, Odra, Pell and Ama.

Their body plans live in the game (src/shared/Rigs/<Name>.luau) and the camp animates the
joints by segment name, so segments, joints and the props at each rig's `points` stay exactly
as the game has them. This adds what only the mesh needs: sculpt detail that the plain-part
fallback leaves out (braids, folds, straps, rivets, freckles, crate planks), a surface style
per color (hair strands, fur, cloth, leather, wood grain, hammered metal), painted-on light,
more atlas space for faces, and a triangle budget of about 6,000 each.

    lune run tools/export_rig.luau Brannoc        (writes tools/blender/Brannoc.rig.json)
    python tools/roster/designs/npcs.py Brannoc   (writes tools/roster/rigs/Brannoc.rig.json)
    python tools/roster/build_roster_mesh.py Brannoc

No name builds all five. Space: studs, facing -Z, feet on y = 0, rot in degrees like
CFrame.Angles. The character's right hand is +X.
"""

import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import along, spike  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
TRIS_SCALE = 1.45  # the game's per-segment plan is about 4,000; the mesh budget is about 6,000

COMMON_STYLES = {
    "hair": "hair",
    "beard": "hair",
    "feather": "hair",
    "featherTip": "hair",
    "rope": "hair",
    "fur": "fur",
    "shirt": "cloth",
    "shirtDark": "cloth",
    "pants": "cloth",
    "jacket": "cloth",
    "jacketDark": "cloth",
    "scarf": "cloth",
    "cloak": "cloth",
    "tunic": "cloth",
    "cloth": "cloth",
    "clothDark": "cloth",
    "vest": "cloth",
    "robe": "cloth",
    "hood": "cloth",
    "mantle": "cloth",
    "leather": "leather",
    "leatherDark": "leather",
    "boots": "leather",
    "hat": "leather",
    "hatDark": "leather",
    "gloves": "leather",
    "purse": "leather",
    "wood": "wood",
    "woodDark": "wood",
    "metal": "metal",
    "metalDark": "metal",
}


def ell(size, pos, rot=None):
    s = {"shape": "ellipsoid", "size": list(size), "pos": list(pos)}
    if rot:
        s["rot"] = list(rot)
    return s


def blk(size, pos, rot=None):
    s = ell(size, pos, rot)
    s["shape"] = "block"
    return s


def band(p0, p1, w, t):
    """A flat strap from p0 to p1: w wide, t thick."""
    s = along(p0, p1, w, t)
    s["shape"] = "block"
    return s


def front_z(center, size, x, y, lift=0.0):
    """z of the front (-Z) surface of an ellipsoid at (x, y), pushed out by lift."""
    cx, cy, cz = center
    hx, hy, hz = (v / 2 for v in size)
    k = 1 - ((x - cx) / hx) ** 2 - ((y - cy) / hy) ** 2
    return cz - hz * math.sqrt(max(0.0, k)) - lift


class Npc:
    def __init__(self, name):
        with open(os.path.join(REPO, "tools", "blender", f"{name}.rig.json")) as f:
            self.rig = json.load(f)
        self.rig["name"] = name
        self.rig["paintLight"] = True
        self.rig["skin"] = {"cell": 0.3, "depth": 0, "noise": 0}
        self.rig["displace"] = {}
        self.rig["uvBoost"] = {"Head": 1.7}
        self.rig["sky"] = (0.42, 0.4, 0.55)
        # Boots, crates, aprons and bracers are blocks: keep their faces flat (heads stay soft).
        self.rig["smoothAngle"] = 35
        for seg in self.rig["segments"]:
            seg["tris"] = int(round(seg["tris"] * TRIS_SCALE / 10) * 10)
            if seg["name"] == "Head":
                seg["voxel"] = 0.025
                seg["smoothAngle"] = 50
            if seg["name"] == "Hips":
                seg["tris"] = int(seg["tris"] * 1.4)  # two legs, boots, soles and toe caps
        self.seg_by_name = {s["name"]: s for s in self.rig["segments"]}

    def colors(self, **cols):
        for k, v in cols.items():
            self.rig["colors"][k] = list(v)

    def add(self, segment, shape, color, side=1):
        assert segment in self.seg_by_name, segment
        assert color in self.rig["colors"], color
        d = {"segment": segment, "color": color}
        d.update(shape)
        if side != 1:
            d["pos"] = [d["pos"][0] * side, d["pos"][1], d["pos"][2]]
            if d.get("rot"):
                rx, ry, rz = d["rot"]
                d["rot"] = [rx, ry * side, rz * side]
        self.rig["details"].append(d)

    def both(self, segment, shape, color):
        self.add(segment, shape, color, 1)
        self.add(segment, shape, color, -1)

    def chain(self, segment, points, w, t, color, shape="block"):
        for p0, p1 in zip(points, points[1:]):
            s = band(p0, p1, w, t) if shape == "block" else along(p0, p1, w, t, overshoot=1.25)
            self.add(segment, s, color)

    def save(self):
        styles = {k: v for k, v in COMMON_STYLES.items() if k in self.rig["colors"]}
        self.rig["styles"] = styles
        path = os.path.join(REPO, "tools", "roster", "rigs", self.rig["name"] + ".rig.json")
        with open(path, "w") as f:
            json.dump(self.rig, f, indent=1)
        total = sum(s["tris"] for s in self.rig["segments"])
        print(f"{self.rig['name']}: {len(self.rig['details'])} details, {total} tri budget -> {path}")


def boots(n, centers, size, y_top, color="boots"):
    """Soles and rounded toe caps on a pair of block boots."""
    for x, z in centers:
        n.add("Hips", blk((size[0] + 0.08, 0.17, size[2] + 0.08), (x, 0.085, z)), "sole")
        n.add("Hips", ell((size[0] - 0.05, y_top * 0.9, 0.7), (x, y_top * 0.5, z - size[2] / 2 + 0.1)), color)


# Brannoc, the blacksmith --------------------------------------------------------------------
def brannoc():
    n = Npc("Brannoc")
    n.colors(
        nose=(214, 126, 94),
        blush=(226, 122, 96),
        rivet=(184, 120, 44),
        metalDark=(46, 48, 56),
        sole=(30, 24, 20),
        soot=(78, 52, 38),
        shirtDark=(116, 42, 30),
    )
    head_c, head_s = (0, 7.0, -0.1), (2.3, 2.4, 2.3)
    torso_c, torso_s = (0, 4.3, 0), (3.8, 3.4, 2.6)

    # Plaited beard braid down the front, a tuft under the gold ring, and handlebar ends.
    for i, (y, w, lean) in enumerate(((5.45, 0.62, 25), (5.07, 0.58, -25), (4.75, 0.5, 25))):
        n.add("Head", ell((w, 0.5, w * 0.95), (0.08 if i % 2 == 0 else -0.08, y, -1.2), (0, 0, lean)), "beard")
    n.add("Head", spike((0, 4.45, -1.2), (0, 3.95, -1.27), 0.5, 0.45), "beard")
    n.both("Head", spike((0.7, 6.85, -1.15), (1.18, 7.12, -0.95), 0.42, 0.36), "beard")
    # Sideburns into a horseshoe of hair round the back of the bald head.
    n.both("Head", ell((0.45, 1.3, 0.8), (1.0, 6.85, -0.35)), "beard")
    n.add("Head", ell((2.35, 1.0, 2.0), (0, 6.95, 0.35)), "beard")
    # A bigger, redder nose and warm cheeks.
    n.add("Head", ell((0.62, 0.52, 0.55), (0, 7.05, -1.3)), "nose")
    n.both("Head", ell((0.5, 0.32, 0.07), (0.62, 7.15, front_z(head_c, head_s, 0.62, 7.15))), "blush")

    # Apron straps over the shoulders and down the back.
    for side in (1, -1):
        pts = [
            (1.05, 4.55, -1.33),
            (1.15, 5.15, front_z(torso_c, torso_s, 1.15, 5.15, 0.07)),
            (1.25, 5.62, -0.2),
            (1.2, 5.0, 0.93),
            (1.0, 3.6, 1.04),
        ]
        n.chain("Torso", [(x * side, y, z) for x, y, z in pts], 0.42, 0.14, "leather")
    # Soot on the apron and a pouch on the belt.
    n.add("Torso", ell((0.7, 0.4, 0.06), (0.45, 3.75, -1.375)), "soot")
    n.add("Torso", ell((0.5, 0.3, 0.06), (-0.55, 2.3, -1.375)), "soot")
    n.add("Torso", blk((0.45, 0.75, 0.75), (-1.75, 2.5, -0.5)), "leatherDark")
    n.add("Torso", blk((0.52, 0.26, 0.8), (-1.78, 2.85, -0.5)), "leather")
    n.add("Torso", ell((0.14, 0.14, 0.14), (-2.03, 2.75, -0.5)), "gold")

    for side in (1, -1):
        arm = "ArmR" if side == 1 else "ArmL"
        # Rolled sleeve at the elbow.
        n.add(arm, ell((1.62, 0.5, 1.62), (2.5, 4.05, -0.05)), "shirtDark", side)
        # Rivets on the gold bracers.
        for dx in (-0.5, 0, 0.5):
            n.add(arm, ell((0.22, 0.22, 0.16), (2.55 + dx, 2.9, -0.88)), "rivet", side)
        for dy in (-0.36, 0.36):
            n.add(arm, blk((1.62, 0.1, 1.62), (2.55, 2.9 + dy, -0.1)), "rivet", side)
        # Knuckles round the fist.
        for dx in (-0.36, -0.12, 0.12, 0.36):
            n.add(arm, ell((0.3, 0.28, 0.3), (2.6 + dx, 2.15, -0.78)), "skin", side)
    # Hammer: leather grip, pommel and dark end caps on the head (the ember stripe stays).
    for y in (1.3, 1.52, 1.74):
        n.add("ArmR", ell((0.5, 0.16, 0.5), (2.6, y, -0.75)), "leather")
    n.add("ArmR", ell((0.5, 0.3, 0.5), (2.6, 1.08, -0.75)), "metalDark")
    for dx in (-0.86, 0.86):
        n.add("ArmR", blk((0.22, 1.12, 1.12), (2.6 + dx, 4.5, -0.75)), "metalDark")

    boots(n, [(0.72, -0.15), (-0.72, -0.15)], (1.35, 0.7, 1.7), 0.7)
    n.save()


# Wren, the Upgrade Table ---------------------------------------------------------------------
def wren():
    n = Npc("Wren")
    n.colors(
        nose=(240, 168, 140),
        freckle=(196, 120, 88),
        mouth=(122, 52, 56),
        jacketDark=(160, 104, 40),
        sole=(30, 26, 24),
    )
    head_c, head_s = (0, 5.9, 0), (2.8, 2.7, 2.6)
    torso_c, torso_s = (0, 3.3, 0), (2.3, 2.4, 1.7)

    # Messy spiky tuft, side bangs and a ponytail tied with her scarf colour.
    n.add("Head", spike((0.15, 7.5, 0.1), (0.55, 8.55, -0.15), 0.55, 0.45), "hair")
    n.add("Head", spike((-0.25, 7.5, 0.35), (-0.6, 8.25, 0.6), 0.45, 0.4), "hair")
    n.add("Head", spike((0.45, 7.4, 0.55), (1.05, 8.05, 0.95), 0.4, 0.35), "hair")
    n.both("Head", spike((1.25, 6.6, -0.5), (1.42, 5.55, -0.72), 0.55, 0.4), "hair")
    n.add("Head", along((0, 6.3, 1.6), (0, 5.2, 2.15), 0.75, 0.62), "hair")
    n.add("Head", ell((0.8, 0.32, 0.8), (0, 6.15, 1.6), (-30, 0, 0)), "scarf")
    # Button nose, freckles and a small smile.
    n.add("Head", ell((0.28, 0.22, 0.2), (0, 5.5, front_z(head_c, head_s, 0, 5.5, 0.04))), "nose")
    for x, y in ((0.32, 5.52), (0.45, 5.45), (0.38, 5.36), (0.55, 5.55)):
        for side in (1, -1):
            n.add("Head", ell((0.075, 0.075, 0.05), (x * side, y, front_z(head_c, head_s, x * side, y))), "freckle")
    n.add("Head", ell((0.36, 0.17, 0.07), (0, 5.17, front_z(head_c, head_s, 0, 5.17))), "mouth")
    n.add("Head", ell((0.44, 0.14, 0.08), (0, 5.245, front_z(head_c, head_s, 0, 5.245))), "skin")
    # Goggle bridge and a glint on each lens.
    n.add("Head", blk((0.35, 0.15, 0.15), (0, 6.8, -1.38)), "brass")
    n.both("Head", ell((0.2, 0.13, 0.05), (0.42, 6.93, -1.45)), "white")

    # Scarf knot, chest pocket with a flap, rolled cuffs.
    n.add("Torso", ell((0.5, 0.45, 0.4), (0.35, 4.05, -0.9)), "scarf")
    z = front_z(torso_c, torso_s, 0.55, 3.75)
    n.add("Torso", blk((0.5, 0.45, 0.1), (0.55, 3.72, z)), "jacketDark")
    n.add("Torso", blk((0.56, 0.14, 0.12), (0.55, 3.97, z - 0.01)), "jacketDark")
    for side in (1, -1):
        arm = "ArmR" if side == 1 else "ArmL"
        n.add(arm, ell((0.92, 0.32, 0.92), (1.47, 2.85, -0.03)), "jacketDark", side)
    # Open jaws on the wrench.
    for dx in (-0.29, 0.29):
        n.add("ArmR", blk((0.22, 0.4, 0.3), (1.5 + dx, 3.35, -0.45)), "metal")
    # Tool belt with a buckle and a screwdriver.
    n.add("Hips", blk((2.12, 0.28, 1.52), (0, 2.25, 0)), "leather")
    n.add("Hips", blk((0.32, 0.26, 0.08), (0, 2.25, -0.77)), "brass")
    n.add("Hips", blk((0.12, 0.6, 0.12), (0.75, 1.85, -0.8)), "metal")
    n.add("Hips", blk((0.22, 0.36, 0.22), (0.75, 2.22, -0.8)), "scarf")
    boots(n, [(0.48, -0.12), (-0.48, -0.12)], (0.95, 0.6, 1.25), 0.6)

    # The upgrade stone as a crystal: four edges and two points.
    sx, sy, sz = 1.9, 6.6, -0.6
    n.add("Stone", blk((0.62, 0.7, 0.62), (sx, sy, sz), (0, 45, 0)), "stone")
    n.add("Stone", spike((sx, sy + 0.2, sz), (sx, sy + 0.72, sz), 0.48), "stone")
    n.add("Stone", spike((sx, sy - 0.2, sz), (sx, sy - 0.66, sz), 0.48), "stone")
    n.save()


# Odra, Hunt Master at the Hunting Board -------------------------------------------------------
def odra():
    n = Npc("Odra")
    n.colors(
        mouth=(92, 42, 38),
        white=(255, 255, 255),
        hatDark=(56, 40, 30),
        quill=(250, 240, 222),
        sole=(32, 26, 22),
        paperDark=(214, 196, 158),
    )
    head_c, head_s = (0, 6.9, -0.05), (2.2, 2.4, 2.2)
    torso_c, torso_s = (0, 4.4, 0), (2.6, 3.0, 1.6)

    # Eye glints and a set mouth above the beard.
    n.both("Head", ell((0.1, 0.1, 0.05), (0.36, 7.05, -1.12)), "white")
    n.add("Head", ell((0.46, 0.07, 0.06), (0, 6.42, front_z(head_c, head_s, 0, 6.42))), "mouth")
    # Hat: a pinched crown, a buckle on the band, and quills down the feathers.
    n.add("Head", ell((0.2, 0.22, 1.5), (0, 9.02, 0.1)), "hatDark")
    n.add("Head", blk((0.38, 0.34, 0.1), (0, 7.95, -1.03)), "trim")
    n.add("Head", blk((0.2, 0.18, 0.12), (0, 7.95, -1.04)), "hatDark")
    n.add("Head", ell((0.52, 2.5, 0.1), (0.9, 9.0, 0.6), (-20, 0, -25)), "quill")
    n.add("Head", ell((0.42, 1.72, 0.08), (1.2, 8.6, 0.8), (-30, 0, -40)), "quill")
    n.add("Head", ell((0.3, 1.2, 0.6), (0.62, 8.75, 0.95), (-35, 0, -10)), "featherTip")

    # Fur mantle: a ring of ragged tufts hanging off the shoulders.
    for i in range(12):
        a = math.radians(i * 30)
        x, z = 1.45 * math.cos(a), 0.05 + 0.95 * math.sin(a)
        n.add("Torso", spike((x, 5.6, z), (x * 1.1, 4.95, 0.05 + (z - 0.05) * 1.1), 0.62, 0.6), "fur")
    # Cloak folds and a ragged hem.
    for x in (-0.95, -0.3, 0.35, 1.0):
        n.add("Torso", ell((0.45, 4.4, 0.32), (x, 3.3, 1.1), (6, 0, 0)), "cloak")
    for x in (-1.1, -0.4, 0.3, 1.0):
        n.add("Torso", spike((x, 1.3, 1.15), (x + 0.05, 0.7, 1.22), 0.55, 0.28), "cloak")
    # Bandolier across the chest, a belt buckle and a pouch.
    pts = [(-0.8, 5.15), (-0.4, 4.7), (0.0, 4.25), (0.4, 3.8), (0.62, 3.6)]
    n.chain("Torso", [(x, y, front_z(torso_c, torso_s, x, y, 0.06)) for x, y in pts], 0.32, 0.12, "leather")
    n.add("Torso", blk((0.42, 0.38, 0.1), (0, 3.35, -0.9)), "trim")
    n.add("Torso", blk((0.45, 0.55, 0.4), (1.15, 3.0, -0.55)), "leather")
    n.add("Torso", blk((0.5, 0.2, 0.45), (1.16, 3.28, -0.56)), "hatDark")
    # Spear: a binding below the bone tip with a feather tied on.
    n.add("Torso", ell((0.36, 0.35, 0.36), (1.82, 8.03, 1.3), (0, 0, -25)), "leather")
    n.add("Torso", spike((1.75, 7.9, 1.3), (2.1, 7.0, 1.45), 0.3, 0.12), "featherTip")

    # The contract: a rolled scroll with a red ribbon.
    n.add("ArmR", ell((0.42, 0.42, 1.62), (1.75, 2.8, -0.5)), "paper")
    for z in (0.3, -1.28):
        n.add("ArmR", ell((0.46, 0.46, 0.1), (1.75, 2.8, z)), "paperDark")
    n.add("ArmR", ell((0.45, 0.45, 0.12), (1.75, 2.8, -0.5)), "seal")
    # Fur cuffs on the boots.
    boots(n, [(0.55, -0.1), (-0.55, -0.1)], (1.05, 1.2, 1.35), 0.75, "leather")
    n.both("Hips", ell((1.2, 0.35, 1.45), (0.55, 1.2, -0.05)), "fur")
    n.save()


# Pell, the Quartermaster ---------------------------------------------------------------------
def pell():
    n = Npc("Pell")
    n.colors(
        purse=(104, 70, 190),
        seam=(74, 50, 32),
        rope=(196, 164, 112),
        paper=(236, 224, 190),
        ribbon=(200, 60, 70),
        metalDark=(56, 60, 68),
        sole=(30, 24, 20),
    )
    torso_c, torso_s = (0, 3.4, -0.1), (3.4, 3.0, 3.0)

    # Curled moustache ends, ears, and a gold pin on the cap.
    n.both("Head", spike((0.85, 5.45, -1.2), (1.15, 5.72, -1.05), 0.36, 0.3), "hair")
    n.both("Head", ell((0.32, 0.55, 0.45), (1.24, 5.85, -0.15)), "skin")
    n.add("Head", ell((0.3, 0.3, 0.08), (0.75, 6.7, -1.04)), "gold")

    # Vest buttons, a coin purse, cuffs.
    for y in (4.05, 3.6):
        n.add("Torso", ell((0.18, 0.18, 0.1), (0, y, -1.7)), "gold")
    n.add("Torso", ell((0.7, 0.8, 0.6), (-1.1, 2.45, -1.05)), "purse")
    n.add("Torso", ell((0.45, 0.15, 0.45), (-1.1, 2.85, -1.05)), "gold")
    for side in (1, -1):
        arm = "ArmR" if side == 1 else "ArmL"
        n.add(arm, ell((0.98, 0.28, 0.98), (2.0, 3.18, -0.22)), "clothDark", side)

    # Crates: plank seams and corner battens.
    for y in (3.3, 3.9):
        n.add("Torso", blk((3.02, 0.06, 0.05), (0, y, 2.91)), "seam")
        for x in (-1.51, 1.51):
            n.add("Torso", blk((0.05, 0.06, 1.82), (x, y, 2)), "seam")
    for x in (-1.38, 1.38):
        n.add("Torso", blk((0.24, 1.82, 0.06), (x, 3.6, 2.92)), "seam")
    n.add("Torso", blk((2.62, 0.06, 0.05), (0.21, 5.3, 2.8), (0, 8, 0)), "seam")
    # Rope ties and rolled ends on the bedroll.
    for x in (-0.9, 0.9):
        n.add("Torso", ell((0.18, 1.0, 1.0), (x, 6.5, 2)), "rope")
    for x in (-1.6, 1.6):
        n.add("Torso", ell((0.1, 0.62, 0.62), (x, 6.5, 2)), "clothDark")
    # Pot rim, lantern cage, and a map sticking out of the pack.
    n.add("Torso", ell((1.08, 0.18, 1.08), (-1.65, 4.75, 2.2)), "metalDark")
    n.add("Torso", blk((0.75, 0.15, 0.75), (1.75, 4.95, 2)), "metal")
    for dx in (-0.3, 0.3):
        for dz in (-0.3, 0.3):
            n.add("Torso", blk((0.1, 0.8, 0.1), (1.75 + dx, 5.4, 2 + dz)), "metal")
    n.add("Torso", ell((0.3, 0.35, 0.1), (1.75, 6.05, 2)), "metal")
    n.add("Torso", along((-1.0, 5.9, 2.7), (-1.3, 7.0, 2.95), 0.34), "paper")
    n.add("Torso", ell((0.4, 0.12, 0.4), (-1.15, 6.45, 2.82), (20, 0, 15)), "ribbon")

    boots(n, [(0.6, -0.15), (-0.6, -0.15)], (1.1, 0.6, 1.4), 0.6)
    n.save()


# Ama, the Nestkeeper at the Nest Spire ------------------------------------------------------
def ama():
    n = Npc("Ama")
    n.colors(rune=(255, 196, 250))
    n.rig["glow"]["rune"] = True

    # Robe folds flaring to the hem, and glowing runes round it.
    for i in range(8):
        a = math.radians(i * 45 + 22.5)
        c, s = math.cos(a), math.sin(a)
        n.add("Robe", along((1.2 * c, 3.1, 1.2 * s), (1.75 * c, 1.05, 1.75 * s), 0.5), "robe")
    for i in range(8):
        a = math.radians(i * 45)
        n.add("Robe", blk((0.22, 0.22, 0.08), (1.75 * math.cos(a), 1.25, 1.75 * math.sin(a)),
                          (0, 90 - math.degrees(a), 45)), "rune")
    # A curling hood tip.
    n.chain("Head", [(0, 8.4, 0.75), (0, 8.75, 1.25), (0, 8.7, 1.7), (0, 8.35, 1.95)], 0.5, 0.45,
            "hood", shape="ellipsoid")
    # Gold frame round the egg brooch.
    n.add("Torso", ell((0.7, 0.9, 0.2), (0, 4.6, -0.88)), "gold")
    # Bell sleeves with glowing hems.
    for side in (1, -1):
        arm = "ArmR" if side == 1 else "ArmL"
        n.add(arm, ell((1.35, 0.85, 1.35), (1.72, 3.7, -0.15)), "robe", side)
        n.add(arm, ell((1.45, 0.28, 1.45), (1.74, 3.3, -0.15)), "trim", side)
    # Crook staff: a curl over the egg lantern, which hangs in a gold cage.
    n.chain("ArmR", [(1.8, 6.75, -0.5), (1.8, 7.25, -0.62), (1.8, 7.45, -0.95), (1.8, 7.3, -1.3),
                     (1.8, 6.95, -1.42)], 0.3, 0.3, "wood", shape="ellipsoid")
    ex, ey, ez = 1.8, 6.2, -1.25
    n.add("ArmR", ell((0.66, 0.86, 0.1), (ex, ey, ez)), "gold")
    n.add("ArmR", ell((0.1, 0.86, 0.66), (ex, ey, ez)), "gold")
    n.add("ArmR", ell((0.36, 0.15, 0.36), (ex, ey + 0.42, ez)), "gold")
    n.add("ArmR", ell((0.1, 0.32, 0.1), (ex, ey + 0.62, ez - 0.05)), "gold")
    # Wisps trail a little tail behind them as they circle.
    centre = (0, 5.5, 0)
    for wx, wy, wz in ((2.4, 5.5, 0), (-1.2, 6.0, 2.1), (-1.2, 5.0, -2.1)):
        dx, dz = -(wz - centre[2]), wx - centre[0]
        length = math.hypot(dx, dz)
        tip = (wx + dx / length * 0.5, wy, wz + dz / length * 0.5)
        n.add("Wisps", along((wx, wy, wz), tip, 0.24, 0.24, overshoot=1.3), "wisp")
    n.save()


BUILDERS = {"Brannoc": brannoc, "Wren": wren, "Odra": odra, "Pell": pell, "Ama": ama}

if __name__ == "__main__":
    for name in sys.argv[1:] or BUILDERS:
        BUILDERS[name]()
