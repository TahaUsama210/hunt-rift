--!strict
-- Crafting checks. Inventories are plain tables: { items = { [name]: count }, gold = number }.

local Crafting = {}

export type Inventory = { items: { [string]: number }, gold: number }

function Crafting.missing(inventory: Inventory, recipe: any): { [string]: number }
	local short = {}
	for item, needed in recipe.materials do
		local have = inventory.items[item] or 0
		if have < needed then
			short[item] = needed - have
		end
	end
	if inventory.gold < recipe.gold then
		short.gold = recipe.gold - inventory.gold
	end
	return short
end

function Crafting.canCraft(inventory: Inventory, recipe: any): boolean
	return next(Crafting.missing(inventory, recipe)) == nil
end

-- Returns a new inventory with materials and gold spent, or nil if it cannot be crafted.
function Crafting.craft(inventory: Inventory, recipe: any, resultName: string): Inventory?
	if not Crafting.canCraft(inventory, recipe) then
		return nil
	end
	local items = table.clone(inventory.items)
	for item, needed in recipe.materials do
		items[item] -= needed
		if items[item] == 0 then
			items[item] = nil
		end
	end
	items[resultName] = (items[resultName] or 0) + 1
	return { items = items, gold = inventory.gold - recipe.gold }
end

return Crafting
