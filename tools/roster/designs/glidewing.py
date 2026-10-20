"""Glidewing: a small gliding lizard with skin sails between its legs. Small monster.

Type: small, flying harasser. Terrain: any with height (cliffs, canopy, badlands, caldera).
Role: run encounters. Swoops in groups of 2 or 3.
Twist: a thief. It flashes its throat fan, then snatches a dropped material or a part you just
broke and glides off with it. Chase it down before it reaches its roost and it drops
everything it stole that run.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Glidewing",
    "Glidewing",
    colors={
        "skin": [70, 110, 120],
        "sail": [232, 120, 48],
        "band": [60, 40, 40],
        "belly": [210, 200, 170],
        "fan": [255, 200, 60],
        "eye": [255, 230, 80],
        "claw": [40, 36, 34],
    },
    hip_height=2.4,
    glow=("eye", "fan"),
    displace={"skin": 1.0, "sail": 0.35, "band": 0.35, "belly": 0.5, "claw": 0.0},
    skin={"cell": 0.12, "depth": 0.025, "noise": 0.02, "pattern": "VORONOI"},
    notes="Small gliding thief: steals dropped materials and part breaks; chase it to get them back.",
)
r.data["sky"] = (0.6, 0.72, 0.86)

r.seg("Body", "Root", "Spine", (0, 2.4, 0), along((0, 2.4, 1.3), (0, 2.6, -1.2), 1.1, 0.8),
      "skin", "body", 350, fine=True)
r.det("Body", along((0, 2.2, 1.1), (0, 2.35, -1.0), 0.8, 0.45), "belly")
for i in range(5):
    z = -0.9 + i * 0.5
    r.det("Body", spike((0, 2.8, z), (0, 3.1, z + 0.3), 0.15, 0.12), "band")

r.seg("Head", "Body", "Neck", (0, 2.65, -1.1), along((0, 2.75, -1.0), (0, 2.6, -2.5), 0.85, 0.6),
      "skin", "head", 400, fine=True, breaksWith="head")
r.det("Head", r.shape("ellipsoid", (0.14, 0.8, 0.9), (0, 2.15, -1.55)), "fan")  # throat fan
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.26, 0.24, 0.28), (0.33, 2.85, -1.85)), "eye", side)
    r.det("Head", spike((0.25, 2.95, -1.3), (0.55, 3.3, -0.8), 0.14), "band", side)  # head spines

for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "Wing", side, "Body", "Shoulder", (0.45, 2.5, -0.3),
         r.shape("ellipsoid", (3.6, 0.16, 2.6), (2.0, 2.45, 0.15)), "sail", "wing", 450, fine=True,
         breaksWith="wing")
    r.det("Wing" + tag, along((0.4, 2.5, -0.8), (3.5, 2.55, -0.7), 0.24, 0.24), "skin", side)  # arm
    r.det("Wing" + tag, along((0.4, 2.4, 0.9), (3.3, 2.42, 1.2), 0.24, 0.24), "skin", side)  # leg
    for x in (1.2, 2.1, 3.0):
        r.det("Wing" + tag, r.shape("ellipsoid", (0.3, 0.2, 2.2 - (x - 1.2) * 0.4), (x, 2.46, 0.2)), "band", side)
    for tip in ((3.6, 2.55, -0.7), (3.4, 2.42, 1.2)):
        for dz in (-0.2, 0.0, 0.2):
            r.det("Wing" + tag, spike(tip, (tip[0] + 0.4, tip[1] - 0.05, tip[2] + dz), 0.08), "claw", side)

r.seg("Tail", "Body", "Tail", (0, 2.4, 1.2), along((0, 2.45, 1.0), (0, 2.25, 5.0), 0.45, 0.4),
      "skin", "tail", 300, fine=True)
r.det("Tail", r.shape("ellipsoid", (1.1, 0.1, 1.0), (0, 2.25, 4.8)), "sail")  # tail rudder
for z in (2.0, 3.0, 4.0):
    r.det("Tail", r.shape("ellipsoid", (0.48, 0.44, 0.25), (0, 2.38 - (z - 1) * 0.04, z)), "band")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
