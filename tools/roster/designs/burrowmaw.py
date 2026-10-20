"""Burrowmaw: a sand-sea burrower with mole-spade arms and a three-petal jaw.

Type: underground. Terrain: Sunscar Dune Sea.
Twist: it hunts blind. The glowing amber pits on its rock plates feel footsteps, so walking
(not running) lets hunters sneak up; breaking the plates deafens it. Its petal jaw opens
into a sand vortex that drags players in.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigkit import Rig, along, mseg, spike  # noqa: E402

r = Rig(
    "Burrowmaw",
    "Burrowmaw",
    colors={
        "hide": [176, 146, 112],
        "plate": [128, 100, 80],
        "band": [96, 64, 46],
        "belly": [222, 196, 150],
        "claw": [236, 226, 204],
        "mouth": [120, 36, 40],
        "pit": [255, 170, 60],
    },
    hip_height=4.0,
    glow=("pit",),
    displace={"hide": 1.0, "plate": 1.0, "band": 0.7, "belly": 0.5, "claw": 0.15, "mouth": 0.3},
    skin={"cell": 0.45, "depth": 0.09, "noise": 0.07, "pattern": "VORONOI"},
    notes="Sunscar Dune Sea. Underground. Blind, senses footsteps through glowing pits; plates break.",
)
r.data["sky"] = (0.86, 0.74, 0.55)


def lerp(a, b, t):
    return [x + (y - x) * t for x, y in zip(a, b)]


def armored(seg, p0, p1, w, h, plates=(0.3, 0.75), pits=True):
    """A rock carapace hugging the back, footstep pits on it, and a pale belly."""
    lift = h * 0.16
    a, b = [p0[0], p0[1] + lift, p0[2]], [p1[0], p1[1] + lift, p1[2]]
    r.det(seg, along(a, b, w * 1.03, h * 0.94, overshoot=0.96), "plate")
    if pits:
        for t in plates:
            c = lerp(a, b, t)
            for side in (1, -1):
                r.det(seg, r.shape("ellipsoid", (0.5, 0.4, 0.5), (w * 0.2, c[1] + h * 0.47 - 0.05, c[2])), "pit", side)
    r.det(seg, along([p0[0], p0[1] - h * 0.3, p0[2]], [p1[0], p1[1] - h * 0.3, p1[2]], w * 0.72, h * 0.5), "belly")


# Front body, rearing up -------------------------------------------------------------------
P = {
    "body": ((0, 3.4, 3.0), (0, 6.6, -3.0), 6.0, 5.2),
    "segA": ((0, 3.6, 2.6), (0, 2.6, 7.8), 5.4, 4.4),
    "segB": ((0, 2.7, 7.4), (0, 2.2, 12.6), 4.6, 3.8),
    "segC": ((0, 2.2, 12.2), (0, 1.8, 16.4), 3.6, 3.0),
    "tail": ((0, 1.8, 16.0), (0, 1.5, 19.8), 2.3, 1.9),
}
p0, p1, w, h = P["body"]
r.seg("Body", "Root", "Spine", (0, 4.0, 0), along(p0, p1, w, h), "hide", "body", 900)
armored("Body", p0, p1, w, h)
for side in (1, -1):
    r.det("Body", along((2.2, 5.6, -2.0), (2.6, 5.4, -3.0), 2.6, 2.6), "hide", side)  # shoulders

# Head with sensing crown, petal jaw ---------------------------------------------------------
r.seg("Head", "Body", "Neck", (0, 7.2, -3.4), along((0, 7.0, -3.0), (0, 8.4, -6.8), 4.6, 4.2),
      "hide", "head", 900, breaksWith="head")
r.det("Head", r.shape("ellipsoid", (4.0, 4.0, 1.2), (0, 8.4, -6.6)), "band")  # rim around the mouth
r.det("Head", r.shape("ellipsoid", (3.0, 3.0, 0.8), (0, 8.45, -7.0)), "mouth")
r.det("Head", along((0, 7.7, -2.9), (0, 9.0, -6.5), 4.7, 3.8), "plate")  # head carapace
for side in (1, -1):
    for i in range(3):
        r.det("Head", r.shape("ellipsoid", (0.5, 0.42, 0.5), (0.7 + i * 0.5, 10.45 - i * 0.18, -4.4 - i * 0.55)), "pit", side)
    r.det("Head", spike((1.4, 10.0, -4.2), (2.4, 11.2, -2.6), 0.7), "plate", side)  # crown horns

MOUTH = (0, 8.45, -7.0)
for name, sx, sy, roll in (("PetalTop", 0.0, 1.0, 0), ("PetalR", 0.87, -0.5, -120), ("PetalL", -0.87, -0.5, 120)):
    base = (MOUTH[0] + sx * 1.35, MOUTH[1] + sy * 1.35, MOUTH[2] + 0.2)
    tip = (MOUTH[0] + sx * 0.35, MOUTH[1] + sy * 0.35, MOUTH[2] - 3.2)
    back = (base[0], base[1], base[2] + 1.0)
    shape = along(back, tip, 2.6, 1.5, roll=roll)
    r.seg(name, "Head", name, base, shape, "plate", "head", 220, fine=True)
    for k in (-1, 0, 1):
        # Teeth along the inner edge of each petal (they point inwards when the jaw closes).
        tb = lerp(base, tip, 0.35 + 0.18 * (k + 1))
        off = (-sy * 0.45 * k, sx * 0.45 * k)
        ib = (tb[0] + off[0] - sx * 0.3, tb[1] + off[1] - sy * 0.3, tb[2])
        it = (ib[0] - sx * 0.7, ib[1] - sy * 0.7, ib[2] - 0.2)
        r.det(name, spike(ib, it, 0.3), "claw")

# Spade arms -------------------------------------------------------------------------------
for side in (1, -1):
    tag = "R" if side == 1 else "L"
    mseg(r, "Arm", side, "Body", "Shoulder", (2.6, 5.6, -2.6),
         along((2.4, 5.8, -2.4), (4.8, 3.9, -4.2), 2.2, 2.4, overshoot=1.15), "hide", "arm", 250)
    mseg(r, "Spade", side, "Arm@", "Elbow", (4.8, 3.9, -4.2),
         along((4.8, 4.0, -4.1), (5.2, 1.4, -5.4), 2.0, 2.0, overshoot=1.1), "hide", "arm", 450, fine=True,
         breaksWith="arm")
    r.det("Spade" + tag, r.shape("ellipsoid", (2.0, 2.0, 2.0), (4.8, 3.9, -4.2)), "hide", side)  # elbow
    r.det("Spade" + tag, r.shape("ellipsoid", (3.6, 1.1, 3.2), (5.4, 1.0, -6.0), (-12, 10, 14)), "hide", side)
    r.det("Spade" + tag, r.shape("ellipsoid", (3.0, 0.7, 2.4), (5.4, 1.45, -5.8), (-12, 10, 14)), "plate", side)
    for i, dx in enumerate((-1.1, -0.35, 0.4, 1.15)):
        reach = 2.0 - abs(dx) * 0.4
        r.det("Spade" + tag, spike((5.4 + dx, 0.85, -7.0), (5.4 + dx * 1.25, 0.25, -7.0 - reach), 0.75, 0.55), "claw", side)

# Segmented body dragging behind -----------------------------------------------------------
attach = "Body"
for name, key, tris in (("SegA", "segA", 700), ("SegB", "segB", 500), ("SegC", "segC", 400), ("Tail", "tail", 300)):
    p0, p1, w, h = P[key]
    r.seg(name, attach, name, p0, along(p0, p1, w, h), "hide", "tail" if name in ("SegC", "Tail") else "body",
          tris, **({"breaksWith": "tail"} if name == "Tail" else {}))
    armored(name, p0, p1, w, h, plates=(0.45,) if name == "Tail" else (0.3, 0.75), pits=name != "Tail")
    attach = name
r.det("Tail", spike((0, 1.6, 19.2), (0, 1.3, 22.0), 2.4, 0.7), "plate")  # spade tail for flicking sand

r.save(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "rigs"))
