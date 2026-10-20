-- Writes a monster's body plan as JSON for the Blender mesh script.
-- Usage: lune run tools/export_rig.luau Thornjaw
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local name = process.args[1] or "Thornjaw"
local rig = require(`../src/shared/Rigs/{name}`)
local path = `tools/blender/{name}.rig.json`
fs.writeFile(path, serde.encode("json", rig, true))
print(`wrote {path}`)
