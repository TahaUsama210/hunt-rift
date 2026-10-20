"""Riftwarden: the elder that tears the rifts. A stag-dragon with a crown of rift crystal.

Type: elder (Weekly Elder Hunt, high tiers). Terrain: any. It arrives through a rift into
whichever biome the contract rolls.
Twist: it tears small rifts that pull in other biomes' hazards (spore clouds, ice walls,
falling pillars, sandstorms) for a few seconds. Each antler branch powers one kind of rift,
so breaking branches strips hazards from its kit. It is the game's name made into a fight.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Riftwarden",
    "Riftwarden",
    colors={
        "hide": [214, 208, 196],
        "slate": [62, 64, 78],
        "void": [44, 34, 74],
        "gold": [214, 176, 96],
        "rift": [255, 226, 150],
        "hoof": [52, 50, 58],
        "eye": [255, 240, 200],
    },
    hip_height=12.0,
    glow=("rift", "eye"),
    displace={"hide": 1.0, "slate": 1.0, "void": 0.6, "gold": 0.3, "hoof": 0.3},
    skin={"cell": 0.42, "depth": 0.06, "noise": 0.05, "pattern": "VORONOI"},
    notes="Elder. Appears in any biome through a rift; borrows other biomes' hazards; antler branches break.",
)
r.data["sky"] = (0.5, 0.52, 0.66)

# Body: deep chest, lean waist, high haunches -------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 12.0, 0), along((0, 12.0, 6.4), (0, 13.2, -5.0), 6.4, 6.6),
      "hide", "body", 1100)
r.det("Body", r.shape("ellipsoid", (6.6, 7.6, 6.4), (0, 12.6, -3.4)), "hide")  # chest
r.det("Body", r.shape("ellipsoid", (6.0, 6.2, 5.6), (0, 12.6, 4.8)), "hide")  # haunches
r.det("Body", along((0, 9.6, 4.0), (0, 10.2, -4.6), 4.4, 3.2), "slate")  # underside
for side in (1, -1):
    r.det("Body", r.shape("ellipsoid", (3.0, 4.6, 4.4), (2.6, 12.4, -3.4)), "hide", side)  # shoulders
    r.det("Body", r.shape("ellipsoid", (3.2, 5.0, 5.0), (2.4, 12.6, 4.8)), "hide", side)  # thighs
    for z, y in ((-2.0, 15.6), (1.0, 15.3), (4.0, 15.4)):
        r.det("Body", r.shape("ellipsoid", (2.2, 0.5, 2.0), (1.9, y - 0.3, z), (0, 0, -32)), "void", side)  # markings
for i in range(6):
    z = -3.8 + i * 1.7
    y = 16.2 - abs(z - 0.5) * 0.12
    r.det("Body", spike((0, y - 0.5, z), (0, y + 1.6, z + 1.2), 0.7, 0.45), "rift")  # rift shards on the spine

# Neck with a gold mane, long skull ------------------------------------------------------------
r.seg("Neck", "Body", "Neck", (0, 14.2, -5.4), along((0, 13.6, -4.6), (0, 18.0, -8.6), 3.2, 3.4),
      "hide", "body", 450)
r.det("Neck", along((0, 13.2, -5.6), (0, 16.8, -8.8), 2.2, 2.0), "slate")
for i in range(5):
    t = i / 4
    base = (0, 15.2 + t * 3.0, -4.6 - t * 3.6)
    for side in (1, -1):
        r.det("Neck", spike((0.6, base[1], base[2]), (1.6, base[1] + 0.6, base[2] + 2.0), 1.0, 0.25), "gold", side)

r.seg("Head", "Neck", "Head", (0, 18.2, -8.8), along((0, 18.6, -8.4), (0, 17.6, -12.6), 2.8, 2.6),
      "hide", "head", 650, fine=True, breaksWith="head")
r.det("Head", along((0, 18.0, -10.8), (0, 17.3, -13.4), 1.8, 1.6), "hide")  # muzzle
r.det("Head", r.shape("ellipsoid", (2.4, 0.5, 2.2), (0, 19.6, -9.6), (-10, 0, 0)), "gold")  # brow plate
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.6, 0.45, 0.8), (1.25, 18.8, -10.4)), "eye", side)
    r.det("Head", along((1.2, 18.4, -9.6), (0.9, 17.4, -12.2), 0.5, 0.3), "void", side)  # tear marks
    r.det("Head", r.shape("ellipsoid", (0.35, 0.3, 0.4), (0.55, 17.6, -13.3)), "slate", side)

r.seg("Jaw", "Head", "Jaw", (0, 17.4, -9.4), along((0, 17.3, -9.4), (0, 16.8, -13.0), 1.8, 0.9),
      "slate", "head", 250, fine=True)

# Antler crown of rift crystal: each branch is breakable ----------------------------------------
r.seg("Antlers", "Head", "Crown", (0, 19.6, -9.4), r.shape("ellipsoid", (2.2, 1.2, 1.6), (0, 19.8, -9.4)),
      "gold", "horn", 700, fine=True, breaksWith="horn")
for side in (1, -1):
    root, mid, tip = (0.9, 20.0, -9.2), (2.8, 22.6, -8.0), (4.2, 25.4, -5.8)
    r.det("Antlers", along(root, mid, 0.75, 0.75, overshoot=1.1), "gold", side)
    r.det("Antlers", spike(mid, tip, 0.65), "rift", side)
    for base, end in (((1.8, 21.3, -8.6), (3.6, 22.4, -10.8)),
                      ((2.8, 22.6, -8.0), (5.0, 23.0, -8.6)),
                      ((3.4, 23.8, -7.0), (2.6, 26.2, -7.6)),
                      ((3.8, 24.6, -6.4), (6.0, 25.6, -4.8))):
        r.det("Antlers", spike(base, end, 0.45), "rift", side)

# Long legs with cloven hooves --------------------------------------------------------------------
for name, hip, knee, foot, uw in (("Front", (2.8, 12.0, -3.6), (3.2, 6.8, -4.6), (3.2, 0.9, -3.8), 2.6),
                                  ("Back", (2.6, 12.4, 4.6), (3.2, 7.4, 7.2), (3.2, 0.9, 5.4), 3.0)):
    for side in (1, -1):
        tag = "R" if side == 1 else "L"
        mseg(r, "Upper" + name, side, "Body", "Hip" + name, hip,
             along(hip, knee, uw, uw * 1.05, overshoot=1.1), "hide", "leg", 250)
        mseg(r, "Lower" + name, side, "Upper" + name + "@", "Knee" + name, knee,
             along(knee, foot, 1.3, 1.4, overshoot=1.08), "slate", "leg", 250)
        r.det("Lower" + name + tag, r.shape("ellipsoid", (1.7, 1.7, 1.8), knee), "hide", side)
        r.det("Lower" + name + tag, r.shape("ellipsoid", (1.5, 1.3, 1.8), (foot[0], 0.65, foot[2] - 0.3)), "hoof", side)
        r.det("Lower" + name + tag, along((foot[0], 2.4, foot[2] + 0.2), (foot[0], 1.0, foot[2] - 0.2), 1.7, 1.7), "gold", side)  # fetlock cuff

# Tail ending in a fan of rift blades -----------------------------------------------------------
r.seg("TailA", "Body", "TailA", (0, 13.4, 7.0), along((0, 13.6, 6.4), (0, 12.0, 12.0), 2.6, 2.4),
      "hide", "tail", 350)
r.seg("TailB", "TailA", "TailB", (0, 12.0, 11.8), along((0, 12.1, 11.4), (0, 10.6, 16.6), 1.6, 1.5),
      "slate", "tail", 350, fine=True, breaksWith="tail")
for yaw_x, y in ((0.0, 1.6), (1.4, 0.8), (-1.4, 0.8), (2.2, -0.4), (-2.2, -0.4)):
    r.det("TailB", spike((0, 10.7, 16.2), (yaw_x, 10.7 + y, 19.2 - abs(yaw_x) * 0.4), 0.8, 0.3), "rift")
for i in range(3):
    z = 7.5 + i * 1.6
    r.det("TailA", spike((0, 14.4 - i * 0.45, z), (0, 15.2 - i * 0.45, z + 1.0), 0.5, 0.4), "rift")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
