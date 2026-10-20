"""Mossback: a docile grazer that carries a small garden on its back.

Type: small, passive herbivore. Terrain: any green biome (marsh, canopy floor, lowlands).
Role: rescue and escort encounters, a gathering point (the herbs on its back), and a pet
when it hatches from an egg. Smaller triangle budget, since herds of 2 to 4 share a scene.
Twist: it panics when a big monster roars and can stampede through the party; calm it
(stand still nearby) and it lets you pick the herbs on its back.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Mossback",
    "Mossback",
    colors={
        "hide": [128, 116, 96],
        "moss": [92, 128, 60],
        "leaf": [64, 104, 50],
        "flower": [236, 132, 160],
        "pollen": [250, 214, 90],
        "belly": [204, 192, 162],
        "horn": [214, 204, 182],
        "eye": [30, 28, 26],
    },
    hip_height=4.2,
    glow=(),
    displace={"hide": 1.0, "moss": 1.0, "leaf": 0.5, "flower": 0.2, "pollen": 0.0, "belly": 0.5, "horn": 0.2, "eye": 0.0},
    skin={"cell": 0.3, "depth": 0.06, "noise": 0.05, "pattern": "VORONOI"},
    notes="Passive grazer: escort and rescue encounters, herb gathering point, pet.",
)
r.data["sky"] = (0.62, 0.72, 0.6)

BACK_C, BACK_R = (0, 5.4, 0.4), (2.2, 1.5, 3.8)


def on_back(x, z):
    """Height of the moss mat at (x, z), so plants sit on it."""
    k = 1 - (x / BACK_R[0]) ** 2 - ((z - BACK_C[2]) / BACK_R[2]) ** 2
    return BACK_C[1] + BACK_R[1] * math.sqrt(max(0.0, k))


# Barrel body with a moss mat --------------------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 4.2, 0), along((0, 4.2, 3.6), (0, 4.6, -3.2), 4.2, 3.6),
      "hide", "body", 800)
r.det("Body", along((0, 3.2, 3.0), (0, 3.4, -2.6), 3.2, 2.0), "belly")
r.det("Body", r.shape("ellipsoid", [k * 2 for k in BACK_R], BACK_C), "moss")
# Herbs, leaves and flowers growing in the moss (the gathering point).
plants = [(-1.0, -2.0), (0.6, -1.2), (-0.4, 0.2), (1.1, 0.8), (-1.2, 1.8), (0.3, 2.4), (0.9, -2.6), (-0.6, 3.2)]
for i, (x, z) in enumerate(plants):
    y = on_back(x, z) - 0.15
    if i % 3 == 0:
        r.det("Body", along((x, y - 0.2, z), (x, y + 0.9, z), 0.18, 0.18), "leaf")
        r.det("Body", r.shape("ellipsoid", (0.8, 0.3, 0.8), (x, y + 0.95, z)), "flower")
        r.det("Body", r.shape("ellipsoid", (0.3, 0.25, 0.3), (x, y + 1.08, z)), "pollen")
    else:
        for a in (0, 120, 240):
            ax, az = math.cos(math.radians(a + i * 20)), math.sin(math.radians(a + i * 20))
            r.det("Body", spike((x, y, z), (x + ax * 0.7, y + 0.8, z + az * 0.7), 0.4, 0.12), "leaf")

# Low head with short brow horns ------------------------------------------------------------
r.seg("Head", "Body", "Neck", (0, 4.4, -3.4), along((0, 4.5, -3.0), (0, 3.6, -5.6), 2.0, 1.8),
      "hide", "head", 500, breaksWith="head")
r.det("Head", along((0, 3.8, -4.6), (0, 3.3, -6.2), 1.4, 1.2), "belly")  # soft muzzle
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (0.32, 0.3, 0.3), (0.85, 4.35, -4.6)), "eye", side)
    r.det("Head", spike((0.6, 4.9, -3.8), (1.4, 5.6, -3.0), 0.45), "horn", side)
    r.det("Head", spike((0.9, 4.4, -3.4), (1.6, 4.6, -2.6), 0.5, 0.2), "hide", side)  # ears
    r.det("Head", r.shape("ellipsoid", (0.25, 0.2, 0.25), (0.35, 3.5, -6.15)), "eye", side)  # nostrils

# Four stumpy legs ------------------------------------------------------------------------------
for name, hip, foot in (("LegF", (1.5, 3.8, -2.0), (1.6, 0.4, -2.2)), ("LegB", (1.5, 3.8, 2.4), (1.6, 0.4, 2.6))):
    for side in (1, -1):
        tag = "R" if side == 1 else "L"
        mseg(r, name, side, "Body", "Hip" + name[-1], hip,
             along(hip, foot, 1.5, 1.6, overshoot=1.1), "hide", "leg", 280)
        r.det(name + tag, r.shape("ellipsoid", (1.5, 0.8, 1.6), (foot[0], 0.4, foot[2] - 0.1)), "horn", side)  # hoof pad

# Stubby tail with a tuft -----------------------------------------------------------------------
r.seg("Tail", "Body", "Tail", (0, 4.6, 3.8), along((0, 4.6, 3.6), (0, 3.4, 5.4), 0.9, 0.9),
      "hide", "tail", 200)
r.det("Tail", r.shape("ellipsoid", (1.0, 1.0, 1.0), (0, 3.3, 5.5)), "moss")

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
