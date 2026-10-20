local T = require("./TestKit")
local Crafting = require("../src/shared/Rules/Crafting")
local Recipes = require("../src/shared/Config/Recipes")
local Loot = require("../src/shared/Config/Loot")

T.test("craft spends materials and gold", function()
	local inv = { items = { CinderwingScale = 3, FlameSac = 1 }, gold = 2000 }
	local after = Crafting.craft(inv, Recipes.FlameLongSword, "FlameLongSword")
	assert(after, "should craft")
	T.equal(after.items.CinderwingScale, 1)
	T.equal(after.items.FlameSac, nil)
	T.equal(after.items.FlameLongSword, 1)
	T.equal(after.gold, 800)
	T.equal(inv.items.CinderwingScale, 3, "original inventory untouched")
end)

T.test("missing lists what is short", function()
	local inv = { items = { ThornjawScale = 1 }, gold = 100 }
	local short = Crafting.missing(inv, Recipes.ThornjawHelm)
	T.equal(short.ThornjawScale, 1)
	T.equal(short.ThornjawCrest, 1)
	T.equal(short.gold, 200)
	T.equal(Crafting.craft(inv, Recipes.ThornjawHelm, "ThornjawHelm"), nil)
end)

T.test("every recipe material can actually drop", function()
	local droppable = {}
	for _, lootTable in Loot do
		for _, drop in lootTable.drops do
			droppable[drop.item] = true
		end
		for _, item in lootTable.breakRewards do
			droppable[item] = true
		end
	end
	for recipeId, recipe in Recipes do
		for item in recipe.materials do
			assert(droppable[item], `{recipeId} needs {item}, which nothing drops`)
		end
	end
end)
