local T = require("./TestKit")
local LootRoll = require("../src/shared/Rules/LootRoll")
local Loot = require("../src/shared/Config/Loot")
local Monsters = require("../src/shared/Config/Monsters")

T.test("weighted pick follows the weights", function()
	local drops = Loot.Cinderwing.drops -- weights 40/30/20/10
	T.equal(LootRoll.pick(drops, 0.0), "CinderwingScale")
	T.equal(LootRoll.pick(drops, 0.39), "CinderwingScale")
	T.equal(LootRoll.pick(drops, 0.40), "CinderwingShell")
	T.equal(LootRoll.pick(drops, 0.95), "CinderwingPlate")
end)

T.test("broken parts add their bonus reward", function()
	local rolls = { 0.1, 0.5, 0.9 }
	local i = 0
	local rewards = LootRoll.rollRewards(Loot.Cinderwing, { "tail" }, function()
		i += 1
		return rolls[i]
	end)
	T.equal(#rewards, 4)
	T.equal(rewards[4], "CinderwingTail")
end)

T.test("every monster points at a loot table that exists", function()
	for id, monster in Monsters do
		assert(Loot[monster.lootTable], `{id} has no loot table`)
		for part in Loot[monster.lootTable].breakRewards do
			assert(monster.breakHp[part], `{id} rewards breaking {part} but it cannot break`)
		end
	end
end)
