local T = require("./TestKit")
local Swing = require("../src/shared/Rules/Swing")
local Weapons = require("../src/shared/Config/Weapons")

local overhead = Weapons.IronGreatSword.swings.overhead -- 0.5 windup, 0.2 active, 0.5 recovery

T.test("a hit only counts while the blade is moving", function()
	local s = Swing.start(overhead, "overhead", 10)
	T.equal(Swing.canHit(s, "overhead", 10.2, 0), false, "still winding up")
	T.equal(Swing.canHit(s, "overhead", 10.6, 0), true)
	T.equal(Swing.canHit(s, "overhead", 11.0, 0), false, "swing finished")
	T.equal(Swing.canHit(s, "overhead", 11.0, 0.35), true, "lag grace")
	T.equal(Swing.canHit(s, "wideSlash", 10.6, 0), false, "wrong move")
end)

T.test("one hit per swing", function()
	local s = Swing.start(overhead, "overhead", 0)
	s.hasHit = true
	T.equal(Swing.canHit(s, "overhead", 0.6, 0), false)
end)

T.test("no new swing until the last one recovers", function()
	T.equal(Swing.canStart(nil, 0, 0), true)
	local s = Swing.start(overhead, "overhead", 0)
	T.equal(Swing.canStart(s, 0.9, 0), false)
	T.equal(Swing.canStart(s, 1.2, 0), true)
	T.equal(Swing.canStart(s, 1.0, 0.35), true, "lag grace")
end)

T.test("every weapon move has a swing with one move per button", function()
	local inputs = { light = true, heavy = true, special = true }
	local styles = { horizontal = true, vertical = true, charged = true, thrust = true }
	for weaponId, weapon in Weapons do
		local used = {}
		for move in weapon.moves do
			local swing = weapon.swings[move]
			assert(swing, `{weaponId}.{move} has no swing`)
			assert(inputs[swing.input], `{weaponId}.{move} input {swing.input}`)
			assert(styles[swing.style], `{weaponId}.{move} style {swing.style}`)
			assert(not used[swing.input], `{weaponId} has two moves on {swing.input}`)
			used[swing.input] = true
			for _, f in { "windup", "active", "recovery", "reach" } do
				assert(type(swing[f]) == "number" and swing[f] > 0, `{weaponId}.{move}.{f}`)
			end
		end
	end
end)
