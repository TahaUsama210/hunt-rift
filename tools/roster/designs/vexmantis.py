"""Vexmantis: a canopy ambusher with scythe arms and a leaf-shaped body.

Type: sharp. Terrain: Elderbough Canopy (giant-tree forest).
Twist: it hides as a cluster of leaves on the giant trunks and drops on hunters. Its leaf
wings flare to blind with pollen, its glowing blade edges leave cuts that bleed, and breaking
a blade turns that arm into a blunt club for the rest of the hunt.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Vexmantis",
    "Vexmantis",
    colors={
        "leaf": [102, 160, 72],
        "dark": [52, 92, 46],
        "vein": [200, 220, 120],
        "belly": [180, 200, 120],
        "blade": [70, 52, 88],
        "edge": [200, 110, 255],
        "eye": [210, 150, 255],
        "mandible": [40, 30, 40],
    },
    hip_height=5.0,
    glow=("edge", "eye"),
    displace={"leaf": 1.0, "dark": 1.0, "vein": 0.5, "belly": 0.6, "blade": 0.4, "mandible": 0.0},
    skin={"cell": 0.8, "depth": 0.035, "noise": 0.025, "pattern": "VORONOI"},
    notes="Elderbough Canopy. Sharp. Ambush from trunks; pollen flare; bleeding cuts; breakable blades.",
)
r.data["sky"] = (0.58, 0.72, 0.6)

# Abdomen: a long leaf with frilled edges ---------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 5.0, 0.5), along((0, 5.0, 0.2), (0, 4.0, 7.8), 3.6, 2.6),
      "leaf", "body", 1100)
r.det("Body", along((0, 4.4, 0.6), (0, 3.6, 7.2), 2.8, 1.6), "belly")
for i in range(5):
    z = 1.6 + i * 1.3
    r.det("Body", r.shape("ellipsoid", (3.4, 2.4, 0.4), (0, 4.75 - i * 0.14, z), (-8, 0, 0)), "dark")  # segment rings
for side in (1, -1):
    for i, (z0, z1, reach) in enumerate(((1.6, 4.2, 2.9), (3.6, 6.2, 2.7), (5.6, 7.8, 2.2))):
        y0, y1 = 4.8 - z0 * 0.1, 4.6 - z1 * 0.1
        r.det("Body", along((1.0, y0, z0), (reach, y1 - 0.3, z1), 1.9, 0.22), "leaf", side)  # side frills
        r.det("Body", along((1.0, y0 + 0.05, z0), (reach, y1 - 0.25, z1), 0.25, 0.26), "vein", side)

# Leaf wings folded on the back, they flare open to throw pollen -----------------------------
r.seg("Wings", "Body", "Wings", (0, 5.8, 0.4), r.shape("ellipsoid", (1.4, 0.8, 2.0), (0, 5.9, 0.6)),
      "dark", "body", 500, fine=True)
for side in (1, -1):
    r.det("Wings", along((0.6, 6.1, 0.0), (1.1, 5.0, 8.4), 2.8, 0.3), "leaf", side)
    r.det("Wings", along((0.6, 6.15, 0.0), (1.1, 5.05, 8.4), 0.3, 0.34), "vein", side)  # midrib
    for t in (0.3, 0.55, 0.8):
        p = (0.6 + 0.5 * t, 6.15 - 1.1 * t, 8.4 * t)
        r.det("Wings", along(p, (p[0] + 1.1, p[1] - 0.15, p[2] + 1.2), 0.18, 0.3), "vein", side)

# Thorax rising up, head on top ----------------------------------------------------------------
r.seg("Thorax", "Body", "Waist", (0, 5.2, -0.2), along((0, 4.9, 0.4), (0, 9.0, -2.2), 1.6, 1.4),
      "leaf", "body", 400)
r.det("Thorax", along((0, 7.0, -1.0), (0, 8.6, -1.9), 2.6, 0.9), "dark")  # collar shield
r.det("Thorax", r.shape("ellipsoid", (2.2, 1.8, 2.2), (0, 5.2, -0.2)), "leaf")

r.seg("Head", "Thorax", "Neck", (0, 9.2, -2.4), r.shape("ellipsoid", (2.6, 1.8, 1.6), (0, 9.6, -2.8)),
      "leaf", "head", 600, fine=True, breaksWith="head")
r.det("Head", spike((0, 9.4, -2.9), (0, 8.0, -3.4), 1.1, 0.9), "leaf")  # triangular face
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (1.3, 1.5, 1.2), (1.25, 9.95, -2.85)), "eye", side)
    r.det("Head", spike((0.35, 8.3, -3.3), (0.1, 7.6, -3.7), 0.35), "mandible", side)
    r.det("Head", spike((0.4, 10.2, -3.0), (2.4, 12.8, -4.4), 0.24), "dark", side)  # antennae

# Scythe arms ------------------------------------------------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "ScytheArm", side, "Thorax", "Shoulder", (0.7, 8.0, -1.7),
         along((0.6, 8.1, -1.6), (1.9, 7.0, -4.6), 1.0, 1.1, overshoot=1.1), "leaf", "arm", 250)
    r.det("ScytheArm" + tag, along((1.0, 7.8, -2.4), (1.8, 7.1, -4.4), 0.6, 0.9), "dark", side)
    mseg(r, "Blade", side, "ScytheArm@", "Elbow", (1.9, 7.0, -4.6),
         along((1.9, 7.1, -4.4), (2.2, 3.6, -7.4), 0.42, 1.7), "blade", "blade", 500, fine=True,
         breaksWith="arm")
    r.det("Blade" + tag, r.shape("ellipsoid", (1.0, 1.0, 1.0), (1.9, 7.0, -4.6)), "leaf", side)  # elbow
    r.det("Blade" + tag, along((1.95, 6.6, -4.4), (2.25, 3.3, -7.1), 0.3, 0.5), "edge", side)  # inner edge
    for k in range(6):
        t = 0.15 + k * 0.13
        p = (1.95 + 0.3 * t, 7.0 - 3.5 * t + 0.4, -4.6 - 2.8 * t + 0.35)
        r.det("Blade" + tag, spike(p, (p[0], p[1] + 0.25, p[2] + 0.7), 0.22), "edge", side)  # serrations
    r.det("Blade" + tag, spike((2.2, 3.8, -7.2), (2.25, 3.0, -8.6), 0.45, 0.8), "edge", side)  # hooked tip

# Four walking legs ------------------------------------------------------------------------------
for name, z, sweep, tris in (("LegM", 0.4, -1.2, 300), ("LegB", 2.0, 1.6, 300)):
    for side in (1, -1):
        tag = "R" if side == 1 else "L"
        knee = (3.6, 6.4, z + sweep * 0.5)
        foot = (5.0, 0.2, z + sweep)
        mseg(r, name, side, "Body", "Hip" + name[-1], (0.9, 4.9, z),
             along((0.8, 4.9, z), knee, 0.6, 0.6, overshoot=1.08), "leaf", "leg", tris)
        r.det(name + tag, along(knee, foot, 0.42, 0.42, overshoot=1.04), "dark", side)
        r.det(name + tag, r.shape("ellipsoid", (0.7, 0.7, 0.7), knee), "leaf", side)
        r.det(name + tag, spike((foot[0], foot[1] + 0.3, foot[2]), (foot[0] + 0.2, 0.02, foot[2] - 0.4), 0.3), "mandible", side)

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
