local T = require("./TestKit")
local Damage = require("../src/shared/Rules/Damage")
local Weapons = require("../src/shared/Config/Weapons")
local Monsters = require("../src/shared/Config/Monsters")
local Combat = require("../src/shared/Config/Combat")

T.test("great sword overhead on Cinderwing head, no crit", function()
	-- 480 * 0.48 * 0.70 = 161.28
	local hit = Damage.computeHit(
		Weapons.IronGreatSword,
		"overhead",
		Monsters.Cinderwing,
		"head",
		Combat,
		0.99
	)
	T.equal(hit.crit, "none")
	T.equal(hit.total, 161)
end)

T.test("affinity crit multiplies raw damage", function()
	local hit = Damage.computeHit(
		Weapons.FlameLongSword,
		"overhead",
		Monsters.Thornjaw,
		"head",
		Combat,
		0.0
	)
	T.equal(hit.crit, "crit")
	-- raw 330 * 0.26 * 0.80 * 1.25 = 85.8, fire 180/10 * 0.25 = 4.5
	T.near(hit.raw, 85.8)
	T.near(hit.element, 4.5)
	T.equal(hit.total, 90)
end)

T.test("fire does nothing to a fire-immune part", function()
	local hit = Damage.computeHit(
		Weapons.FlameLongSword,
		"thrust",
		Monsters.Cinderwing,
		"wing",
		Combat,
		0.99
	)
	T.equal(hit.element, 0)
end)

T.test("negative affinity gives weak hits", function()
	T.equal(Damage.critKind(-20, 0.1), "weak")
	T.equal(Damage.critKind(-20, 0.5), "none")
end)

T.test("damage never drops below the minimum", function()
	local weak = { attack = 1, affinity = 0, moves = { poke = 1 } }
	local hit = Damage.computeHit(weak, "poke", Monsters.Cinderwing, "body", Combat, 0.5)
	T.equal(hit.total, Combat.minDamage)
end)

T.test("every weapon move hits every monster part for positive damage", function()
	for weaponId, weapon in Weapons do
		for move in weapon.moves do
			for monsterId, monster in Monsters do
				for part in monster.hitzones do
					local hit = Damage.computeHit(weapon, move, monster, part, Combat, 0.5)
					assert(hit.total >= 1, `{weaponId}.{move} on {monsterId}.{part}`)
				end
			end
		end
	end
end)
