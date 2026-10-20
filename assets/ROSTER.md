# Hunt Rift monster roster

Original monsters, each built to Taha's mesh rule: a high-poly sculpt (about 1 to 1.6 million
triangles) decimated to about 6,000 triangles, with the lost detail baked back as a 1024 color
map, normal map and glow mask (use as SurfaceAppearance ColorMap / NormalMap; the glow mask
marks parts to light up). None of them copy a Monster Hunter design: each takes a familiar
role (flyer, burrower, brute, ambusher) and gives it a body plan and gimmick of its own.
Already taken elsewhere: Thornjaw (teal raptor) and Cinderwing (fire wyvern).

Art direction (Taha, 2026-10-19): slightly realistic with a stylised feel. Readable
silhouettes and bold color blocks first, real-looking surface detail (scales, stone, chitin)
from the baked maps.

| Monster | Type | Terrain | Size (studs, L x H) | Tris | Breakable parts |
|---|---|---|---|---|---|
| Shardkite | flying, sharp | Frostspire Cliffs | 30 x 13, 26 wingspan | 6,184 | head, wing tips, tail drill |
| Burrowmaw | underground | Sunscar Dune Sea | 30 x 11 | 5,751 | head, spade arms, tail |
| Puffgourd | round | Glowmire Fungal Marsh | 11 x 11 | 5,165 | lantern crown, head |
| Cragmaul | aggressive | Shattered Badlands | 20 x 12 | 5,696 | boulder ridge, head horn, forearms, tail club |
| Vexmantis | sharp, ambush | Elderbough Canopy | 16 x 13 | 5,298 | head, scythe blades |

## Shardkite: the frost-cliff blade kite
A long-tailed flyer whose wing "feathers" are loose ice blades. Four eyes, a crystal crown.
- **Fight hook:** rains its wing blades down as shards, then flies with gaps in its wings
  (less lift, lower dives) until they regrow. The tail ends in a crystal drill it spins into
  the ground to raise ice walls that split the party.
- **Weak to:** fire; breaking the wing tips grounds it for longer.
- **Rewards feel:** translucent ice-blade weapons, shard-feather cosmetic cape.

## Burrowmaw: the blind dune burrower
A segmented sand burrower with mole-spade arms and a three-petal jaw. Rock carapace on its back.
- **Fight hook:** it is blind. The glowing amber pits on its plates feel footsteps, so walking
  instead of sprinting lets hunters sneak in. Breaking its plates deafens it. The petal jaw
  opens into a sand vortex that drags players in.
- **Weak to:** water; the belly when it rears up.
- **Rewards feel:** sandstone armor, amber-pit trinkets, a burrowing pet larva.

## Puffgourd: the spore-lantern toad
A round, frog-like marsh lump that grows glowing mushroom lanterns on its back.
- **Fight hook:** it inflates and rolls through the swamp. Each lantern holds a different spore
  (sleep, confusion, poison); popping a lantern removes that attack. Pop them all and it
  deflates and flops over for a big damage window.
- **Weak to:** fire and thunder; the lantern crown.
- **Rewards feel:** glowing mushroom hats, a pocket Puffgourd pet. Good beginner-to-mid monster.

## Cragmaul: the badlands boulder brute
A knuckle-walking brute with a ram horn and a ridge of ore-rich boulders on its back.
- **Fight hook:** rips boulders off its back to throw. Breaking the ridge spills bonus ore. In
  a rage its red veins glow and it chains charges, smashing canyon pillars that fall on anyone
  nearby, itself included (lure it into pillars on purpose).
- **Weak to:** ice; the horn and forearms break.
- **Rewards feel:** stone gauntlet weapons, glowing-vein armor set.

## Vexmantis: the canopy ambusher
A mantis-like hunter with scythe arms, a leaf-shaped body and folded leaf wings.
- **Fight hook:** hides as a cluster of leaves on giant trunks and drops on hunters. Flares its
  leaf wings to blind with pollen. Its glowing blade edges cause bleeding. Breaking a blade
  turns that arm into a blunt club for the rest of the hunt.
- **Weak to:** fire; the head and blades.
- **Rewards feel:** twin-scythe weapons, leaf-camo armor, glowing blade-edge trims.

# Batch 2 (2026-10-20)

Fills the plan's 8th launch slot and gives the run loop its other monster roles. Small
monsters get a smaller triangle budget (about 2,000 to 2,800) because 2 to 5 share a scene;
apex and elder monsters keep about 6,000.

| Monster | Role | Terrain | Size (studs, L x H) | Tris | Breakable parts |
|---|---|---|---|---|---|
| Slagstrider | apex, 8th launch monster | Emberdeep Caldera (volcanic, shared with Cinderwing) | 18 x 17, 16 wide | 5,448 | crust, head, tail |
| Riftwarden | elder (Weekly Elder Hunt) | any biome, through a rift | 33 x 26 | 5,843 | antler crown, head, tail |
| Gnasher | small, pack | any (recolor per biome) | 9 x 5.5 | 2,746 | head (alpha mask) |
| Mossback | small, passive, pet | green biomes | 12 x 7.5 | 2,617 | head |
| Glidewing | small, flying thief | cliffs, canopy, caldera | 8 long, 8 span | 1,948 | head, wings |

## Slagstrider: the lava stilt-walker
Four stilt legs with knees high above the body, a spear beak, an obsidian crust and a glowing
slag sac under its neck.
- **Fight hook:** spits slag globs that cool into temporary walls and stepping stones. The crust
  only cracks when it overheats; water attacks cool it so the crust shatters and exposes the sac.
- **Weak to:** water; the sac once the crust is off.

## Riftwarden: the elder that tears the rifts
A stag-dragon with a crown of rift-crystal antlers, a gold mane and a fan of rift blades on its tail.
- **Fight hook:** tears small rifts that pull in other biomes' hazards (spore clouds, ice walls,
  falling pillars, sandstorms). Each antler branch powers one kind of rift; breaking branches
  strips hazards from its kit. It turns the game's name into a fight and reuses existing hazards.

## Gnasher: the pack hunter (small)
Hyena-like, with a bone face mask and quill mane. Packs of 3 to 5 follow an alpha; break the
alpha's mask and the pack scatters. Powers the Pack Hunt hazard. Recolor per biome.

## Mossback: the garden grazer (small, passive)
A docile grazer with herbs and flowers growing in the moss on its back. It panics and
stampedes when a big monster roars; calm it to pick the herbs. Escort in rescue encounters,
and a pet when hatched.

## Glidewing: the gliding thief (small)
A gliding lizard with orange skin sails. Flashes its throat fan, steals a dropped material or a
fresh part break, and glides off; catch it before its roost to get everything back.

Thornjaw still has no home biome in the plan. It would fit the Elderbough Canopy floor or a
starter lowland biome.

Bestiary page with renders: https://claude.ai/artifact/3CZMQMScTZwEiMb6eSwKBy

## Files
- `assets/<Name>/`: the FBX (one mesh per moving piece plus a Root cube), the color, normal and
  glow maps, two previews and `report.json` (triangles per piece, before and after).
- `tools/roster/designs/<name>.py`: the body plan (shapes, colors, joints, hitzones, triangle
  budget per piece). Running it writes `tools/roster/rigs/<Name>.rig.json`.
- `tools/roster/build_roster_mesh.py <Name>`: sculpt, decimate to budget, bake, export to
  `assets/<Name>/`. `--quick` gives a fast shapes-only render while designing.
- `assets/STUDIO-IMPORT.md`: how to bring a monster into Studio.
- `tools/roster/rescale_fbx.py <Name>`: rewrites an FBX in studs without rebuilding (used once to
  fix the first exports, which were in centimetres and imported 100 times too big).

## Wiring notes for the game thread
Rigs use the same format as `Rigs/GreatJagras.luau` (segments with joint, jointAt, hitzone,
breaksWith; details baked in). They have no animations yet: each needs idle/walk/attack poses
and a Config/Monsters + Config/Loot entry before it can spawn.
