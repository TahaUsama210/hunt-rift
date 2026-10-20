--!strict
-- Part breaking: tracks damage per body part and reports which parts just broke.

local Parts = {}

-- Returns a new damage table and a list of parts that crossed their break threshold.
function Parts.applyPartDamage(
	monster: any,
	partDamage: { [string]: number },
	part: string,
	amount: number
): ({ [string]: number }, { string })
	local nextDamage = table.clone(partDamage)
	local before = nextDamage[part] or 0
	local after = before + amount
	nextDamage[part] = after

	local broken = {}
	local threshold = monster.breakHp[part]
	if threshold and before < threshold and after >= threshold then
		table.insert(broken, part)
	end
	return nextDamage, broken
end

return Parts
