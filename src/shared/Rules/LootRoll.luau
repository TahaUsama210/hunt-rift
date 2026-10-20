--!strict
-- Weighted loot rolls. `rng` returns a number in [0, 1); pass Random.new():NextNumber in
-- the game and a fixed sequence in tests.

local LootRoll = {}

function LootRoll.pick(drops: { { item: string, weight: number } }, roll: number): string
	local totalWeight = 0
	for _, drop in drops do
		totalWeight += drop.weight
	end
	local target = roll * totalWeight
	for _, drop in drops do
		target -= drop.weight
		if target < 0 then
			return drop.item
		end
	end
	return drops[#drops].item
end

function LootRoll.rollRewards(
	lootTable: any,
	brokenParts: { string },
	rng: () -> number
): { string }
	local rewards = {}
	for _ = 1, lootTable.rolls do
		table.insert(rewards, LootRoll.pick(lootTable.drops, rng()))
	end
	for _, part in brokenParts do
		local bonus = lootTable.breakRewards[part]
		if bonus then
			table.insert(rewards, bonus)
		end
	end
	return rewards
end

return LootRoll
