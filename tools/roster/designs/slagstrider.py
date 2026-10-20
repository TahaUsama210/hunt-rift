"""Slagstrider: a four-legged lava wader that walks on stilts through magma lakes.

Type: elemental, tall. Terrain: Emberdeep Caldera (the volcanic biome it shares with Cinderwing).
Twist: it carries molten slag in a glowing throat sac and spits globs that cool into
temporary walls and stepping stones. Its obsidian crust only cracks when it overheats;
water attacks cool it so the crust shatters, which exposes the glowing sac and belly.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Slagstrider",
    "Slagstrider",
    colors={
        "ash": [92, 86, 84],
        "crust": [34, 30, 32],
        "magma": [255, 110, 30],
        "sac": [255, 150, 50],
        "beak": [60, 50, 48],
        "eye": [255, 200, 80],
        "toe": [70, 60, 58],
    },
    hip_height=10.5,
    glow=("magma", "sac", "eye"),
    displace={"ash": 1.0, "crust": 1.0, "beak": 0.2, "toe": 0.5},
    skin={"cell": 0.4, "depth": 0.07, "noise": 0.05, "pattern": "VORONOI"},
    notes="Emberdeep Caldera. Volcanic stilt-walker. Spits slag walls; water cracks its crust.",
)
r.data["sky"] = (0.62, 0.48, 0.42)

# Compact body slung between four tall legs ---------------------------------------------
r.seg("Body", "Root", "Spine", (0, 10.5, 0), along((0, 10.2, 2.6), (0, 11.2, -2.6), 4.2, 3.8),
      "ash", "body", 1000)
r.det("Body", along((0, 9.4, 2.0), (0, 10.0, -2.0), 3.0, 1.8), "magma")  # molten belly seam
for side in (1, -1):
    r.det("Body", r.shape("ellipsoid", (1.8, 1.8, 1.8), (1.6, 10.4, -1.4)), "ash", side)  # leg sockets
    r.det("Body", r.shape("ellipsoid", (1.8, 1.8, 1.8), (1.6, 10.3, 1.4)), "ash", side)

# Obsidian crust on the back: breakable once overheated --------------------------------------
r.seg("Crust", "Body", "Crust", (0, 12.0, 0), along((0, 11.4, 2.8), (0, 12.4, -2.8), 4.0, 2.4),
      "crust", "back", 600, breaksWith="back")
for i, z in enumerate((-2.0, -0.4, 1.2, 2.6)):
    y = 12.6 - i * 0.25
    r.det("Crust", spike((0, y - 0.3, z), (0, y + 1.6 - i * 0.2, z + 1.1), 1.4, 0.6), "crust")
    for side in (1, -1):
        r.det("Crust", spike((0.9, y - 0.4, z), (1.9, y + 0.7, z + 0.9), 1.0, 0.5), "crust", side)
        # Glowing cracks between plates.
        r.det("Crust", along((0.3, y - 0.05, z + 0.5), (1.5, y - 0.35, z + 0.6), 0.22, 0.25), "magma", side)

# Long neck with the slag sac, spear-beaked head ----------------------------------------------
r.seg("Neck", "Body", "Neck", (0, 11.4, -2.4), along((0, 11.2, -2.0), (0, 14.6, -4.6), 1.7, 1.8),
      "ash", "body", 450)
r.det("Neck", r.shape("ellipsoid", (2.1, 2.6, 2.8), (0, 12.0, -3.8), (20, 0, 0)), "sac")  # slag sac
r.det("Neck", r.shape("ellipsoid", (2.2, 0.5, 2.0), (0, 13.0, -3.6), (20, 0, 0)), "crust")  # sac rim
for i in range(3):
    t = i / 3
    r.det("Neck", spike((0, 12.2 + t * 2.4, -2.0 - t * 2.0), (0, 12.9 + t * 2.4, -1.3 - t * 2.0), 0.4, 0.6), "crust")

r.seg("Head", "Neck", "Head", (0, 14.7, -4.7), along((0, 15.0, -4.2), (0, 14.7, -7.0), 1.7, 1.5),
      "ash", "head", 650, fine=True, breaksWith="head")
r.det("Head", spike((0, 14.7, -6.6), (0, 14.2, -9.8), 0.85, 0.6), "beak")
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.42, 0.36, 0.5), (0.7, 15.1, -5.9)), "eye", side)
    r.det("Head", spike((0.4, 15.5, -4.8), (1.2, 16.6, -2.6), 0.5, 0.35), "crust", side)  # swept crest
r.det("Head", spike((0, 15.7, -5.0), (0, 17.2, -2.8), 0.6, 0.4), "crust")

r.seg("Jaw", "Head", "Jaw", (0, 14.4, -5.0), along((0, 14.35, -5.0), (0, 13.95, -9.2), 0.75, 0.42),
      "beak", "head", 250, fine=True)

# Four stilt legs, knees high above the body ---------------------------------------------------
for name, hz, kz, fz in (("LegF", -1.4, -3.4, -5.4), ("LegB", 1.4, 3.4, 5.6)):
    for side in (1, -1):
        tag = "R" if side == 1 else "L"
        hip, knee, foot = (1.7, 10.3, hz), (4.6, 14.0, kz), (7.0, 0.5, fz)
        mseg(r, "Upper" + name, side, "Body", "Hip" + name[-1], hip,
             along(hip, knee, 1.1, 1.1, overshoot=1.12), "ash", "leg", 220)
        mseg(r, "Lower" + name, side, "Upper" + name + "@", "Knee" + name[-1], knee,
             along(knee, foot, 0.7, 0.75, overshoot=1.05), "crust", "leg", 330, fine=True)
        r.det("Lower" + name + tag, r.shape("ellipsoid", (1.2, 1.2, 1.2), knee), "ash", side)
        r.det("Lower" + name + tag, spike((5.0, 12.0, kz), (5.6, 13.6, kz * 1.05), 0.5), "crust", side)  # knee spur
        r.det("Lower" + name + tag, r.shape("ellipsoid", (1.6, 0.5, 1.6), foot), "toe", side)
        for dx, dz in ((0.9, -0.5), (0.0, -1.0), (-0.9, -0.5)):
            r.det("Lower" + name + tag, spike((foot[0], 0.4, foot[2]), (foot[0] + dx * 1.3, 0.15, foot[2] + dz * 1.6), 0.45, 0.3), "toe", side)
        # A drip of glowing slag down the shin.
        r.det("Lower" + name + tag, along((5.4, 9.0, kz * 1.2), (6.0, 5.0, fz * 0.92), 0.4, 0.4), "magma", side)

# Short tail with a drooping slag fin -----------------------------------------------------------
r.seg("Tail", "Body", "Tail", (0, 10.6, 2.8), along((0, 10.6, 2.4), (0, 9.0, 6.8), 1.7, 1.5),
      "ash", "tail", 300, breaksWith="tail")
r.det("Tail", spike((0, 9.6, 5.6), (0, 7.8, 7.8), 1.1, 0.5), "crust")
r.det("Tail", along((0, 10.5, 3.4), (0, 9.2, 6.2), 0.4, 0.3), "magma")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
