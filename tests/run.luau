-- Runs every *.spec.luau file with Lune, outside Roblox. Exit code 1 on any failure.
local fs = require("@lune/fs")
local process = require("@lune/process")
local T = require("./TestKit")

local specs = {}
for _, name in fs.readDir("tests") do
	if string.match(name, "%.spec%.luau$") then
		table.insert(specs, name)
	end
end
table.sort(specs)
for _, name in specs do
	require("./" .. string.gsub(name, "%.luau$", ""))
end

local r = T.results()
for _, failure in r.failures do
	print("FAIL " .. failure)
end
print(`{r.passed} passed, {r.failed} failed`)
process.exit(if r.failed > 0 then 1 else 0)
