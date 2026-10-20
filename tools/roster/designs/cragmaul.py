"""Cragmaul: a knuckle-walking badlands brute with a ram horn and a back full of boulders.

Type: aggressive. Terrain: Shattered Badlands canyons.
Twist: it hoards ore-rich boulders on its back and rips them off to throw. Breaking the ridge
spills bonus ore. In a rage its red veins glow and it chains charges, smashing canyon pillars
that then fall on whoever stands nearby, the monster included.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Cragmaul",
    "Cragmaul",
    colors={
        "hide": [74, 70, 72],
        "dark": [40, 36, 38],
        "rock": [134, 118, 98],
        "belly": [120, 104, 96],
        "horn": [228, 214, 186],
        "vein": [255, 70, 50],
        "eye": [255, 90, 60],
    },
    hip_height=6.0,
    glow=("vein", "eye"),
    displace={"hide": 1.0, "dark": 1.0, "rock": 1.0, "belly": 0.6, "horn": 0.15},
    skin={"cell": 0.5, "depth": 0.1, "noise": 0.08, "pattern": "VORONOI"},
    notes="Shattered Badlands. Aggressive. Throws boulders off its back; rage veins glow; chains charges.",
)
r.data["sky"] = (0.8, 0.66, 0.56)


def boulder(seg, pos, size, rot, veins=True, side=1):
    # A rounded stone with a smaller turned block inside whose corners poke out as facets.
    r.det(seg, r.shape("ellipsoid", size, pos, rot), "rock", side)
    r.det(seg, r.shape("block", [k * 0.74 for k in size], pos, (rot[0] + 25, rot[1] + 40, rot[2] + 15)), "rock", side)
    if veins:
        # A glowing crack across the stone, just under its surface.
        r.det(seg, r.shape("ellipsoid", (size[0] * 0.95, size[1] * 0.18, size[2] * 0.2),
                           (pos[0], pos[1] + size[1] * 0.08, pos[2]), (rot[0], rot[1] + 35, rot[2])), "vein", side)


# Torso ------------------------------------------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 6.0, 0), along((0, 6.2, 3.2), (0, 8.8, -2.2), 7.0, 6.2),
      "hide", "body", 1100)
r.det("Body", r.shape("ellipsoid", (5.6, 4.4, 4.6), (0, 5.8, 3.4)), "hide")  # hips
r.det("Body", along((0, 5.4, 2.4), (0, 6.6, -2.6), 5.2, 3.6), "belly")
for side in (1, -1):
    r.det("Body", r.shape("ellipsoid", (4.4, 4.8, 4.8), (2.6, 9.2, -1.4)), "hide", side)  # shoulders
    for i, (y, z) in enumerate(((9.0, -2.4), (7.8, -0.2), (7.0, 2.2))):
        r.det("Body", along((3.0 - i * 0.2, y + 0.6, z - 0.8), (3.2 - i * 0.2, y - 0.6, z + 0.8), 0.5, 0.3), "vein", side)

# Boulder ridge it throws from --------------------------------------------------------------
r.seg("Boulders", "Body", "Ridge", (0, 10.6, 0), r.shape("ellipsoid", (4.6, 1.8, 7.4), (0, 10.4, 0.2), (8, 0, 0)),
      "dark", "back", 600, breaksWith="back")
boulder("Boulders", (0, 11.7, -1.6), (2.8, 2.2, 2.5), (10, 20, 8))
boulder("Boulders", (0.4, 11.4, 1.3), (2.5, 2.1, 2.6), (-6, -30, -10))
boulder("Boulders", (-0.2, 10.9, 3.6), (2.0, 1.7, 2.0), (20, 45, 0))
for side in (1, -1):
    boulder("Boulders", (1.8, 10.8, -0.2), (1.6, 1.4, 1.8), (0, 15, 25), veins=False, side=side)

# Head: low ram with a forward horn, brow and tusks ------------------------------------------
r.seg("Head", "Body", "Neck", (0, 8.2, -3.4), along((0, 8.0, -3.0), (0, 7.2, -7.0), 3.8, 3.3),
      "hide", "head", 700, fine=True, breaksWith="head")
r.det("Head", r.shape("ellipsoid", (4.2, 1.4, 2.4), (0, 8.9, -4.8), (-10, 0, 0)), "rock")  # brow plate
r.det("Head", spike((0, 7.8, -6.4), (0, 10.0, -9.4), 2.1, 1.7), "horn")  # ram horn
r.det("Head", spike((0, 9.6, -8.8), (0, 11.6, -8.9), 1.1), "horn")  # its hooked tip
r.det("Head", spike((0, 8.8, -5.8), (0, 10.4, -6.8), 0.9), "horn")
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.55, 0.4, 0.4), (1.25, 8.3, -5.6)), "eye", side)
    r.det("Head", spike((1.6, 7.0, -5.8), (2.6, 7.6, -7.4), 0.6), "horn", side)  # upper tusks
    r.det("Head", r.shape("ellipsoid", (0.4, 0.3, 0.4), (0.6, 7.3, -7.3)), "dark", side)

r.seg("Jaw", "Head", "Jaw", (0, 6.8, -3.6), along((0, 6.6, -3.6), (0, 6.0, -6.8), 3.2, 1.6),
      "belly", "head", 300, fine=True)
for side in (1, -1):
    r.det("Jaw", spike((1.0, 6.2, -6.2), (1.4, 7.6, -7.0), 0.5), "horn", side)  # lower tusks

# Massive arms on knuckles -------------------------------------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "Arm", side, "Body", "Shoulder", (3.4, 9.2, -1.6),
         along((3.6, 9.6, -1.4), (5.5, 5.4, -3.2), 3.3, 3.5, overshoot=1.1), "hide", "arm", 350)
    mseg(r, "Forearm", side, "Arm@", "Elbow", (5.5, 5.4, -3.2),
         along((5.5, 5.8, -3.1), (5.7, 1.6, -3.9), 3.0, 3.1, overshoot=1.05), "hide", "arm", 550,
         breaksWith="arm")
    r.det("Forearm" + tag, r.shape("ellipsoid", (2.8, 2.8, 2.8), (5.5, 5.4, -3.2)), "hide", side)  # elbow
    r.det("Forearm" + tag, r.shape("ellipsoid", (3.4, 2.3, 3.2), (5.8, 1.15, -4.1)), "dark", side)  # fist
    for dz in (-1.2, -0.1, 1.0):
        r.det("Forearm" + tag, r.shape("ellipsoid", (1.4, 1.0, 1.0), (5.9, 0.6, -4.6 + dz * 0.6)), "rock", side)
    boulder("Forearm" + tag, (6.9, 4.0, -3.4), (1.4, 3.6, 2.6), (-10, 0, -8), side=side)  # gauntlet stone
    boulder("Forearm" + tag, (6.8, 2.2, -3.8), (1.2, 1.8, 2.2), (0, 0, 10), veins=False, side=side)

# Short hind legs ----------------------------------------------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "Leg", side, "Body", "Hip", (2.6, 5.4, 3.6),
         along((2.6, 5.8, 3.4), (3.3, 2.6, 4.4), 2.8, 3.0, overshoot=1.1), "hide", "leg", 200)
    mseg(r, "Shin", side, "Leg@", "Knee", (3.3, 2.6, 4.4),
         along((3.3, 2.8, 4.4), (3.1, 0.6, 3.4), 2.0, 2.0, overshoot=1.1), "dark", "leg", 250)
    r.det("Shin" + tag, r.shape("ellipsoid", (2.4, 1.1, 3.2), (3.1, 0.5, 2.8)), "dark", side)
    for dx in (-0.7, 0.0, 0.7):
        r.det("Shin" + tag, spike((3.1 + dx, 0.5, 1.6), (3.1 + dx * 1.2, 0.2, 0.9), 0.45), "horn", side)

# Stub tail with a stone club ----------------------------------------------------------------
r.seg("Tail", "Body", "Tail", (0, 6.2, 4.8), along((0, 6.2, 4.6), (0, 4.6, 8.8), 2.2, 2.0),
      "hide", "tail", 300, breaksWith="tail")
boulder("Tail", (0, 4.4, 9.2), (2.8, 2.4, 2.8), (15, 30, 5))

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
