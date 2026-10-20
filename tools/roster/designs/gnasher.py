"""Gnasher: a hyena-like pack hunter with a bone face mask. Small monster.

Type: small, pack. Terrain: any (recolored per biome by swapping its colors table).
Role: run encounters and the Pack Hunt hazard. 3 to 5 at once, so it gets a smaller
triangle budget than the apex monsters.
Twist: the pack follows an alpha with a bigger quill mane. Break the alpha's bone mask and
the rest of the pack scatters.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Gnasher",
    "Gnasher",
    colors={
        "hide": [138, 110, 82],
        "stripe": [70, 52, 40],
        "belly": [196, 176, 140],
        "bone": [226, 214, 190],
        "mane": [60, 44, 36],
        "eye": [255, 220, 90],
        "mouth": [110, 40, 40],
    },
    hip_height=3.4,
    glow=("eye",),
    displace={"hide": 1.0, "stripe": 1.0, "belly": 0.5, "bone": 0.25, "mane": 1.0, "mouth": 0.0},
    skin={"cell": 0.18, "depth": 0.04, "noise": 0.03, "pattern": "VORONOI"},
    notes="Small pack hunter for run encounters; alpha's mask breaks to scatter the pack.",
)
r.data["sky"] = (0.72, 0.66, 0.56)

# Sloped body: heavy shoulders, low hips ------------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 3.4, 0), along((0, 3.0, 2.2), (0, 4.0, -1.8), 2.2, 2.2),
      "hide", "body", 650)
r.det("Body", r.shape("ellipsoid", (2.4, 2.6, 2.2), (0, 4.0, -1.4)), "hide")  # shoulders
r.det("Body", along((0, 2.6, 1.6), (0, 3.2, -1.6), 1.5, 1.2), "belly")
for side in (1, -1):
    for z in (-1.0, 0.0, 1.0):
        r.det("Body", along((0.75, 4.3 - (z + 1) * 0.25, z - 0.2), (1.0, 3.5 - (z + 1) * 0.25, z + 0.1), 0.3, 0.2), "stripe", side)
for i in range(6):
    z = -2.0 + i * 0.6
    y = 5.0 - i * 0.22
    r.det("Body", spike((0, y - 0.3, z), (0, y + 0.55, z + 0.6), 0.35, 0.2), "mane")  # quill mane

# Head with a bone mask, and jaw ------------------------------------------------------------------
r.seg("Head", "Body", "Neck", (0, 4.2, -2.2), along((0, 4.3, -2.0), (0, 3.9, -3.8), 1.4, 1.3),
      "hide", "head", 500, fine=True, breaksWith="head")
r.det("Head", along((0, 4.0, -3.4), (0, 3.7, -4.7), 0.85, 0.8), "hide")  # muzzle
r.det("Head", along((0, 4.55, -2.5), (0, 4.12, -4.45), 1.0, 0.42), "bone")  # face mask over the snout
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.24, 0.2, 0.26), (0.48, 4.35, -3.3)), "eye", side)
    r.det("Head", spike((0.45, 4.7, -2.3), (0.75, 5.5, -1.7), 0.42, 0.25), "hide", side)  # ears
    r.det("Head", spike((0.3, 4.6, -2.6), (0.8, 4.9, -1.5), 0.24), "bone", side)  # mask horns

r.seg("Jaw", "Head", "Jaw", (0, 3.7, -2.6), along((0, 3.65, -2.6), (0, 3.45, -4.5), 0.75, 0.45),
      "belly", "head", 200, fine=True)
r.det("Jaw", r.shape("ellipsoid", (0.6, 0.12, 1.4), (0, 3.7, -3.8)), "mouth")
for side in (1, -1):
    r.det("Jaw", spike((0.25, 3.7, -4.2), (0.25, 4.0, -4.25), 0.12), "bone", side)  # fangs

# Legs: long front, short back --------------------------------------------------------------------
for name, hip, knee, foot in (("LegF", (0.9, 3.8, -1.4), (1.0, 1.9, -1.6), (1.0, 0.25, -1.9)),
                              ("LegB", (0.8, 3.0, 1.6), (0.95, 1.6, 2.1), (0.9, 0.25, 1.5))):
    for side in (1, -1):
        tag = "R" if side == 1 else "L"
        mseg(r, name, side, "Body", "Hip" + name[-1], hip,
             along(hip, knee, 0.75, 0.85, overshoot=1.12), "hide", "leg", 300)
        r.det(name + tag, along(knee, foot, 0.45, 0.45, overshoot=1.1), "stripe", side)
        r.det(name + tag, r.shape("ellipsoid", (0.6, 0.6, 0.6), knee), "hide", side)
        r.det(name + tag, r.shape("ellipsoid", (0.55, 0.35, 0.8), (foot[0], 0.2, foot[2] - 0.25)), "mane", side)

# Short bushy tail --------------------------------------------------------------------------------
r.seg("Tail", "Body", "Tail", (0, 3.4, 2.4), along((0, 3.4, 2.2), (0, 2.6, 3.8), 0.7, 0.7),
      "mane", "tail", 200)
r.det("Tail", r.shape("ellipsoid", (0.8, 0.8, 1.0), (0, 2.5, 3.8)), "mane")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
