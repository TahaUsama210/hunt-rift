"""Puffgourd: a round, frog-like marsh lump that grows glowing spore lanterns on its back.

Type: round. Terrain: Glowmire Fungal Marsh.
Twist: it inflates into a ball and rolls through the swamp. Each lantern on its back holds a
different spore (sleep, confusion, poison); popping them changes what it can throw at you,
and popping all of them makes it deflate and flop over for a big damage window.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Puffgourd",
    "Puffgourd",
    colors={
        "hide": [96, 128, 72],
        "dark": [58, 80, 52],
        "belly": [214, 206, 160],
        "sac": [222, 140, 170],
        "cap": [176, 58, 160],
        "spore": [255, 120, 230],
        "eye": [230, 240, 90],
        "pupil": [20, 24, 16],
        "mouth": [92, 40, 52],
    },
    hip_height=4.5,
    glow=("spore", "eye"),
    displace={"hide": 1.0, "dark": 1.0, "belly": 0.4, "sac": 0.2, "cap": 0.35, "mouth": 0.0},
    skin={"cell": 0.6, "depth": 0.12, "noise": 0.06, "pattern": "VORONOI"},
    notes="Glowmire Fungal Marsh. Round. Inflates and rolls; spore lanterns can be popped one by one.",
)
r.data["sky"] = (0.55, 0.62, 0.58)

BODY_C, BODY_R = (0, 5.4, 0.6), (4.6, 3.8, 4.6)


def on_body(yaw_deg, pitch_deg, lift=0.0):
    """A point on the body surface and the outward direction there."""
    yw, pt = math.radians(yaw_deg), math.radians(pitch_deg)
    d = (math.sin(yw) * math.cos(pt), math.sin(pt), math.cos(yw) * math.cos(pt))
    p = [c + rr * k for c, rr, k in zip(BODY_C, BODY_R, d)]
    return [a + k * lift for a, k in zip(p, d)], d


def lantern(seg, yaw, pitch, size, side=1):
    """A mushroom lantern: stalk, cap, and glowing gills under the cap."""
    base, d = on_body(yaw, pitch, -0.4)
    top = [b + k * size * 1.3 for b, k in zip(base, d)]
    r.det(seg, along(base, top, size * 0.45), "belly", side)
    cap0 = [b + k * size * 1.0 for b, k in zip(base, d)]
    cap1 = [b + k * size * 1.75 for b, k in zip(base, d)]
    r.det(seg, along(cap0, cap1, size * 1.3, size * 1.3), "cap", side)
    gill = [b + k * size * 1.05 for b, k in zip(base, d)]
    gill1 = [b + k * size * 1.3 for b, k in zip(base, d)]
    r.det(seg, along(gill, gill1, size * 1.15, size * 1.15), "spore", side)
    for a in (0, 120, 240):
        # Glowing spots on the cap.
        u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        spot = [cap1[0] - d[0] * size * 0.18 + u[0] * size * 0.35, cap1[1] - d[1] * size * 0.18,
                cap1[2] - d[2] * size * 0.18 + u[1] * size * 0.35]
        r.det(seg, r.shape("ellipsoid", (size * 0.22,) * 3, spot), "spore", side)


# Body --------------------------------------------------------------------------------------
r.seg("Body", "Root", "Spine", (0, 4.5, 0), r.shape("ellipsoid", [k * 2 for k in BODY_R], BODY_C),
      "hide", "body", 1600)
r.det("Body", r.shape("ellipsoid", (7.2, 5.0, 7.0), (0, 4.0, 0.2)), "belly")
for side in (1, -1):
    for yaw, pitch, s in ((60, 10, 1.4), (100, 25, 1.1), (130, 5, 1.3), (80, -10, 1.0), (115, 45, 1.2)):
        p, _ = on_body(yaw, pitch, -0.5)
        r.det("Body", r.shape("ellipsoid", (s * 1.4, s * 0.9, s * 1.6), p), "dark", side)
    for yaw, pitch, s in ((50, 40, 0.9), (150, 30, 0.8), (95, 60, 0.7)):
        lantern("Body", yaw, pitch, s, side)
lantern("Body", 0, 35, 0.9)

# Lantern crown on top: the big breakable cluster -------------------------------------------
r.seg("Crown", "Body", "Crown", (0, 9.0, 0.8), r.shape("ellipsoid", (3.0, 1.6, 3.0), (0, 8.9, 0.8)),
      "hide", "pod", 700, breaksWith="pod")
for yaw, pitch, s in ((0, 90, 1.6), (40, 68, 1.1), (-40, 68, 1.1), (180, 70, 1.2)):
    lantern("Crown", yaw, pitch, s)

# Head and jaw: a wide frog face fused to the front of the body -----------------------------
r.seg("Head", "Body", "Neck", (0, 5.0, -2.4), r.shape("ellipsoid", (7.0, 3.6, 4.6), (0, 5.0, -3.8)),
      "hide", "head", 900, breaksWith="head")
for side in (1, -1):
    r.det("Head", r.shape("ellipsoid", (1.9, 1.9, 1.9), (2.1, 6.6, -3.6)), "hide", side)
    r.det("Head", r.shape("ellipsoid", (1.2, 1.2, 1.2), (2.25, 6.95, -4.15)), "eye", side)
    r.det("Head", r.shape("ellipsoid", (0.75, 0.24, 0.3), (2.35, 7.05, -4.7)), "pupil", side)
    r.det("Head", r.shape("ellipsoid", (0.4, 0.3, 0.4), (0.7, 5.6, -6.0)), "dark", side)  # nostrils
r.det("Head", r.shape("ellipsoid", (6.6, 0.35, 3.8), (0, 4.0, -4.1)), "mouth")

r.seg("Jaw", "Head", "Jaw", (0, 4.0, -2.6), r.shape("ellipsoid", (6.6, 1.8, 4.2), (0, 3.3, -4.0)),
      "belly", "head", 450)
r.det("Jaw", r.shape("ellipsoid", (5.2, 3.0, 3.6), (0, 2.9, -2.6)), "sac")  # throat sac
r.det("Jaw", r.shape("ellipsoid", (6.2, 0.3, 3.6), (0, 4.0, -4.1)), "mouth")

# Legs: short front legs, big frog haunches --------------------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "LegF", side, "Body", "HipF", (3.2, 4.2, -1.8),
         along((3.3, 4.4, -1.6), (4.4, 1.2, -2.6), 2.2, 2.2, overshoot=1.1), "hide", "leg", 380)
    r.det("LegF" + tag, r.shape("ellipsoid", (3.0, 0.8, 3.0), (4.6, 0.4, -3.2)), "dark", side)
    for dx, dz in ((-0.9, -1.4), (0.1, -1.7), (1.0, -1.3)):
        r.det("LegF" + tag, r.shape("ellipsoid", (0.8, 0.6, 0.8), (4.6 + dx, 0.35, -3.2 + dz)), "belly", side)
    mseg(r, "LegB", side, "Body", "HipB", (3.6, 4.6, 2.8),
         along((3.4, 4.8, 2.4), (4.9, 2.2, 3.8), 3.2, 3.6, overshoot=1.1), "hide", "leg", 380)
    r.det("LegB" + tag, along((4.9, 2.4, 3.8), (4.8, 0.8, 1.4), 1.8, 1.6), "hide", side)
    r.det("LegB" + tag, r.shape("ellipsoid", (3.2, 0.8, 3.6), (5.0, 0.4, 0.6)), "dark", side)
    for dx, dz in ((-1.0, -1.4), (0.1, -1.8), (1.1, -1.3)):
        r.det("LegB" + tag, r.shape("ellipsoid", (0.8, 0.6, 0.8), (5.0 + dx, 0.35, 0.6 + dz)), "belly", side)

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
