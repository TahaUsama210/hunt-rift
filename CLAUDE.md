# MonsterHunt: rules for Claude Code

A Monster Hunter style co-op combat game for Roblox. Code lives in files and is synced into
Studio with Rojo. Studio is never the source of truth.

## The four checks
Run `./scripts/check.sh` (Windows PowerShell: `powershell -ExecutionPolicy Bypass -File scripts\check.ps1`) after every change.
All four must pass before anything is tested in Studio:
1. `rojo build` puts the game together and catches broken files.
2. `lune run tests/run.luau` checks the game rules still hold.
3. `selene src` catches sloppy code (tests are linted from inside `tests/`, which has its own
   `selene.toml` because Lune uses string requires that the Roblox rules reject).
4. `stylua --check src tests` checks formatting (run `stylua src tests` to fix).

## Standing rules
1. Code lives in `src/`, never typed straight into Studio. Studio edits get lost on the next sync.
2. Every number worth tweaking (HP, damage, hitzones, drop weights, prices) lives in
   `src/shared/Config/`. Balancing means changing data, not code.
3. Game rules live in `src/shared/Rules/` as pure functions: no `game`, no `Instance`, no
   `require` of other modules. Config and randomness come in as arguments so Lune can test them.
4. Every client/server message is named in `src/shared/Remotes.luau` and nowhere else.
5. The server decides damage and loot. The client only says what it tried to hit; the server
   checks every id against config before using it.

## Adding things
- New monster: add it to `Config/Monsters.luau` and give it a table in `Config/Loot.luau`.
  The tests already check every monster has loot and every weapon move works on every part.
  To spawn it, it also needs `rig` (a body plan in `src/shared/Rigs/`, with an animation for
  every attack plus flinch and death), `ai`, and an entry in `Config/Hunt.luau` spawns.
- Roster monster (designed in `tools/roster/`): run `python tools/roster/rig_to_luau.py <Name>`
  to copy its body plan into `src/shared/Rigs/<Name>.luau`, then fill in by hand below the
  generated block: the walk cycle (`gait`: which joints are legs, knees, tail, neck, jaw),
  `fallsOff` (segments that disappear when their part breaks) and the animations. Rerunning the
  script after a design change only rewrites the generated block.
- New weapon: add it to `Config/Weapons.luau` with its moves' motion values and a `swings`
  entry per move (button, arm style, timings, reach).
- New rule: put it in `Rules/`, add a `tests/<Name>.spec.luau`, then call it from the server.
- New biome portal or station: add it to `Config/Hub.luau`. A portal opens once its `monsterId`
  can spawn (the tests check this); until then it shows as coming soon.

## Monster meshes
Roblox caps a mesh at 20,000 triangles. Aim for about 6,000 for a whole monster, and keep the
detail by baking it from a high-poly sculpt into a normal map and a color map
(SurfaceAppearance). The pipeline does this from the rig's body plan:
1. `lune run tools/export_rig.luau Thornjaw` (writes `tools/blender/Thornjaw.rig.json`)
2. `blender -b -P tools/blender/build_monster_mesh.py -- Thornjaw`
   (writes `assets/Thornjaw/`: the FBX, both 1024 maps, previews and a triangle report)
3. Import the FBX in Studio and put the model at `ServerStorage/Assets/Thornjaw` (SETUP.md 7).
Each rig segment becomes its own mesh named like the segment, plus a `Root` cube the game uses
to line the pieces up. The game falls back to plain parts for any piece it cannot find, so the
monster always works without the import. Triangle budgets per segment live in the rig (`tris`).

## How the fight works
- Server (`MonsterController`): chases the nearest player with AlignPosition/AlignOrientation,
  picks attacks with `Rules/MonsterAI`, fires `MonsterAction`, and damages players in the hit
  area halfway through the attack's active time.
- Client (`MonsterAnimator`): writes Motor6D.Transform in PreSimulation for the walk cycle and
  the rig's attack poses, and shows the red warning during windup.
- Player (`PlayerCombat`): click/E/R swing the sword; during the active window the blade's box
  is checked against monster parts with a `Hitzone` attribute and `AttackHit` is sent once.
  The server only accepts it inside that swing's window (`Rules/Swing`) and within reach.

## Rift Camp (the hub)
- Players spawn in Rift Camp, built from plain parts by `server/HubWorld` 400 studs above the
  hunting ground. Design boards (layout, UI kit, every menu): the "Hunt Rift hub and UI" canvas.
- `server/Hub` tracks who stands on each portal pad (`Rules/PortalParty`: up to 4, 10 second
  countdown, Go now) and moves the party to the portal's `arrival`. The player attribute
  `Location` is `"Camp"` or the portal id. After a kill, the hunters of that monster go back
  to camp and get its rewards.
- Station prompts (F, since E is the heavy attack) open the client menus in `client/Stations`,
  drawn with the shared kit in `client/Ui`. The server re-checks every action (crafting only
  at the blacksmith). The nest raid countdown is `Rules/NestRotation` on server time.
- The camp screen (`client/CampHud`: wallet, profile card, nest timer, party card) and the side
  tiles (`client/Menus`: Gear, Codex, Eggs, Areas, Rewards, Profile, the rest "coming soon")
  share one ScreenGui with the station menus, and `Ui.modal` keeps one panel open at a time.
  Screens read `client/PlayerData`, the last profile the server sent; they never decide anything.
- `server/Profiles` saves items, gold, Rift Shards and the daily streak (DataStore
  `HuntRiftProfiles_v1`). A profile that failed to load is never saved, so a DataStore outage
  cannot wipe anyone. Daily rewards are `Rules/DailyRewards` on UTC days, amounts in
  `Config/DailyRewards`. The Areas teleport (`Teleport`) only works while in camp.

## Traps
Write each mistake that cost real time here, with the reason, so it is not repeated.
- FBX exports must use `global_scale=0.01`. Studio ignores the FBX unit and reads the raw
  numbers as studs, and Blender's default export adds a 100x (centimetre) node scale, so
  monsters imported 100 times too big (a 2-stud Root came in at 200).
  `tools/roster/rescale_fbx.py <Name>` fixes an old FBX in place without rebaking.
- Monster distances are flat (x/z only), and camp floats right above the hunting ground, so
  anything that looks for players near a monster must skip `Location == "Camp"`.
