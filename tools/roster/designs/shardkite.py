"""Shardkite: a frost-cliff flyer whose wings are fans of loose ice blades.

Type: flying, sharp. Terrain: Frostspire Cliffs.
Twist: the wing "feathers" are crystal blades it can shed as a rain of shards; four eyes; the
tail ends in a crystal drill it spins into the ground to raise ice walls.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Shardkite",
    "Shardkite",
    colors={
        "hide": [206, 220, 232],
        "dark": [58, 66, 112],
        "belly": [236, 240, 244],
        "crystal": [110, 214, 245],
        "eye": [190, 250, 255],
        "pupil": [20, 24, 40],
        "claw": [40, 44, 60],
    },
    hip_height=6.5,
    glow=("crystal", "eye"),
    displace={"hide": 1.0, "dark": 1.0, "belly": 0.6, "claw": 0.0, "pupil": 0.0},
    skin={"cell": 0.28, "depth": 0.06, "noise": 0.04, "pattern": "VORONOI"},
    notes="Frostspire Cliffs. Flying, sharp. Sheds wing blades as a shard rain; tail drill raises ice walls.",
)
r.data["sky"] = (0.62, 0.74, 0.9)

# Body -------------------------------------------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 6.5, 0), along((0, 7.0, 3.0), (0, 8.3, -3.6), 4.6, 4.2),
      "hide", "body", 900)
r.det("Body", along((0, 6.5, 2.2), (0, 7.6, -3.0), 3.6, 3.0), "belly")
for side in (1, -1):
    # Shoulders for the wings and thighs for the legs.
    r.det("Body", along((1.4, 8.6, -2.6), (2.1, 8.8, -1.4), 2.0, 1.8), "hide", side)
    r.det("Body", along((1.4, 7.0, 0.4), (2.0, 7.0, 1.8), 2.4, 2.6), "hide", side)
    for i, z in enumerate((-2.4, -0.6, 1.2)):
        r.det("Body", along((1.2, 8.9 - i * 0.3, z - 0.6), (1.9, 8.6 - i * 0.3, z + 0.6), 1.1, 0.4), "dark", side)
for i in range(5):
    z = -2.8 + i * 1.4
    y = 9.9 - i * 0.28
    r.det("Body", spike((0, y - 0.4, z), (0, y + 1.1 - i * 0.12, z + 1.0), 0.45, 0.8), "crystal")

# Neck, head and jaw -----------------------------------------------------------------------
r.seg("Neck", "Body", "Neck", (0, 8.6, -3.2), along((0, 8.4, -3.0), (0, 10.7, -6.2), 2.2, 2.3),
      "hide", "body", 350)
r.det("Neck", along((0, 8.2, -3.6), (0, 10.0, -6.0), 1.5, 1.4), "belly")
for i in range(3):
    t = i / 3
    r.det("Neck", spike((0, 9.4 + t * 2.0, -3.4 - t * 2.6), (0, 10.2 + t * 2.0, -2.9 - t * 2.6), 0.35, 0.6), "crystal")

r.seg("Head", "Neck", "Head", (0, 10.6, -6.4), along((0, 11.1, -5.8), (0, 10.5, -9.4), 2.4, 1.9),
      "hide", "head", 750, fine=True, breaksWith="head")
r.det("Head", along((0, 10.7, -8.0), (0, 10.1, -10.9), 1.3, 1.0), "hide")  # beak-like snout
r.det("Head", spike((0, 10.4, -10.2), (0, 10.0, -11.2), 0.6, 0.5), "claw")  # beak tip
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.55, 0.5, 0.6), (0.95, 11.1, -7.3)), "eye", side)
    r.det("Head", r.shape("ellipsoid", (0.42, 0.4, 0.48), (0.8, 10.8, -8.15)), "eye", side)
    r.det("Head", r.shape("ellipsoid", (0.12, 0.42, 0.2), (1.2, 11.1, -7.35)), "pupil", side)
    r.det("Head", r.shape("ellipsoid", (0.1, 0.32, 0.16), (1.0, 10.8, -8.2)), "pupil", side)
    # Crown of crystal horns sweeping back.
    r.det("Head", spike((0.6, 11.5, -6.6), (1.7, 12.8, -4.2), 0.5), "crystal", side)
    r.det("Head", spike((0.9, 11.2, -7.0), (2.2, 11.6, -5.2), 0.38), "crystal", side)
r.det("Head", spike((0, 11.7, -6.8), (0, 13.6, -4.6), 0.55), "crystal")

r.seg("Jaw", "Head", "Jaw", (0, 10.2, -6.8), along((0, 10.1, -6.6), (0, 9.7, -10.1), 1.6, 0.8),
      "belly", "head", 300, fine=True)
for side in (1, -1):
    for i in range(3):
        z = -8.0 - i * 0.7
        r.det("Jaw", spike((0.45, 10.05, z), (0.45, 10.55, z - 0.1), 0.18), "belly", side)

# Legs: backward-bending bird legs with three forward talons -------------------------------
for side in (1, -1):
    mseg(r, "UpperLeg", side, "Body", "Hip", (2.0, 7.0, 1.0),
         along((2.0, 7.4, 1.4), (2.2, 4.4, -0.4), 2.0, 2.2), "hide", "leg", 220)
    mseg(r, "LowerLeg", side, "UpperLeg@", "Knee", (2.2, 4.5, -0.4),
         along((2.2, 4.6, -0.5), (2.1, 1.2, 1.4), 1.1, 1.2), "dark", "leg", 300, fine=True)
    tag = "R" if side == 1 else "L"
    r.det("LowerLeg" + tag, r.shape("ellipsoid", (1.5, 1.5, 1.5), (2.2, 4.5, -0.4)), "hide", side)  # knee
    r.det("LowerLeg" + tag, r.shape("ellipsoid", (1.0, 1.0, 1.0), (2.1, 1.1, 1.5)), "dark", side)  # ankle
    r.det("LowerLeg" + tag, along((2.1, 0.8, 1.6), (2.1, 0.55, -0.9), 1.3, 0.7), "dark", side)
    for dx, yaw in ((-0.45, -0.3), (0.0, 0.0), (0.45, 0.3)):
        r.det("LowerLeg" + tag, spike((2.1 + dx, 0.5, -0.8), (2.1 + dx * 1.6, 0.25, -1.9), 0.28, 0.35), "claw", side)
    r.det("LowerLeg" + tag, spike((2.1, 0.6, 1.5), (2.1, 0.25, 2.3), 0.26), "claw", side)

# Wings: an arm and a hand, each fanned with ice blades ------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "Wing", side, "Body", "Shoulder", (2.0, 8.8, -2.2),
         along((1.8, 8.8, -2.2), (7.2, 9.8, -1.0), 1.1, 1.0), "dark", "wing", 450, fine=True)
    mseg(r, "WingTip", side, "Wing@", "Wrist", (7.2, 9.8, -1.0),
         along((7.0, 9.8, -1.0), (13.0, 9.4, -2.8), 0.8, 0.75), "dark", "wing", 500, fine=True,
         breaksWith="wing")
    r.det("WingTip" + tag, spike((7.3, 10.0, -1.3), (7.5, 10.5, -2.6), 0.32), "claw", side)  # thumb hook
    r.det("WingTip" + tag, r.shape("ellipsoid", (1.2, 1.1, 1.2), (7.2, 9.8, -1.0)), "dark", side)  # wrist
    for x, length, splay in ((3.2, 4.6, 0.05), (4.6, 5.4, 0.1), (6.0, 6.2, 0.15)):
        y = 8.9 + (x - 1.8) * 0.18
        root = (x, y, -1.8 + (x - 1.8) * 0.2)
        tip = (x + length * splay, y - 0.6, root[2] + length)
        r.det("Wing" + tag, spike(root, tip, 1.6, 0.26), "crystal" if x > 4 else "hide", side)
    for i, (t, length) in enumerate(((0.12, 6.6), (0.35, 6.2), (0.58, 5.4), (0.8, 4.4), (1.0, 3.2))):
        x = 7.2 + t * 5.8
        y = 9.8 - t * 0.4
        z = -1.0 - t * 1.8
        splay = 0.25 + t * 0.6
        tip = (x + length * splay, y - 0.7, z + length * (1 - splay * 0.4))
        r.det("WingTip" + tag, spike((x, y, z), tip, 1.6 - t * 0.4, 0.26), "crystal" if i % 2 == 0 else "hide", side)

# Tail ending in a crystal drill -----------------------------------------------------------
r.seg("TailA", "Body", "TailA", (0, 7.4, 3.6), along((0, 7.6, 2.8), (0, 6.9, 8.2), 2.6, 2.3),
      "hide", "tail", 350)
r.seg("TailB", "TailA", "TailB", (0, 6.9, 8.0), along((0, 7.0, 7.6), (0, 6.1, 12.6), 1.7, 1.5),
      "hide", "tail", 250)
r.seg("TailC", "TailB", "TailC", (0, 6.1, 12.4), along((0, 6.2, 12.0), (0, 5.5, 15.8), 1.1, 1.0),
      "dark", "tail", 350, fine=True, breaksWith="tail")
for seg, z0, z1, y0 in (("TailA", 4.0, 7.4, 8.6), ("TailB", 8.6, 11.8, 7.7)):
    n = 3
    for i in range(n):
        z = z0 + (z1 - z0) * i / (n - 1)
        y = y0 - (z - z0) * 0.17
        r.det(seg, spike((0, y - 0.3, z), (0, y + 0.6, z + 0.7), 0.35, 0.55), "crystal")
for seg, z0, z1 in (("TailA", 3.6, 7.6), ("TailB", 8.4, 12.0)):
    for side in (1, -1):
        r.det(seg, along((0.6, 7.0 - (z0 - 3.6) * 0.18, z0), (0.5, 6.8 - (z1 - 3.6) * 0.18, z1), 0.8, 0.35), "dark", side)
tip = (0, 5.4, 16.0)
r.det("TailC", spike(tip, (0, 5.2, 18.8), 0.95), "crystal")
for side in (1, -1):
    r.det("TailC", spike((0.3 * side, 5.6, 15.4), (1.2 * side, 6.4, 17.6), 0.5), "crystal")
    r.det("TailC", spike((0.3 * side, 5.2, 15.4), (1.0 * side, 4.4, 17.4), 0.45), "crystal")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
