# MonsterHunt

Starter project for a Monster Hunter style Roblox combat game.

- `src/shared/Config/` monsters, weapons, loot, recipes, combat tuning (plain data)
- `src/shared/Rules/` damage, part breaks, loot rolls, crafting (pure, tested)
- `src/shared/Rigs/` monster body plans and their attack poses (plain data)
- `src/shared/Remotes.luau` every client/server message name
- `src/server/` hunt state, monster AI and spawning, the player's sword
- `src/client/` sword input and hit detection, monster animation, health bars
- `tools/blender/` turns a body plan into a ~6,000 triangle mesh with baked detail
- `assets/` the generated monster meshes and textures, ready to import into Studio
- `tests/` Lune tests for the rules, run with `lune run tests/run.luau`

Start with `SETUP.md`. Rules for Claude Code are in `CLAUDE.md`.
