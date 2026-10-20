--!strict
-- Hit damage. Pure functions: every number comes in as an argument, so tests can
-- check the maths without Roblox. `roll` is a number in [0, 1) for the crit check.

local Damage = {}

export type HitResult = {
	raw: number,
	element: number,
	total: number,
	crit: "none" | "crit" | "weak",
}

function Damage.critKind(affinity: number, roll: number): "none" | "crit" | "weak"
	local chance = math.abs(affinity) / 100
	if roll >= chance then
		return "none"
	end
	return if affinity > 0 then "crit" else "weak"
end

function Damage.computeHit(
	weapon: any,
	moveName: string,
	monster: any,
	part: string,
	tuning: any,
	roll: number
): HitResult
	local motionValue = weapon.moves[moveName]
	assert(motionValue, `unknown move {moveName}`)
	local hitzone = monster.hitzones[part]
	assert(hitzone, `unknown part {part}`)

	local crit = Damage.critKind(weapon.affinity or 0, roll)
	local critMul = if crit == "crit"
		then tuning.critMultiplier
		elseif crit == "weak" then tuning.weakHitMultiplier
		else 1

	local raw = weapon.attack * (motionValue / 100) * (hitzone / 100) * critMul

	local element = 0
	if weapon.element then
		local zones = monster.elementHitzones[weapon.element]
		local elementZone = if zones then zones[part] or 0 else 0
		element = (weapon.elementPower / tuning.elementDivisor) * (elementZone / 100)
	end

	local total = math.max(tuning.minDamage, math.floor(raw + element))
	return { raw = raw, element = element, total = total, crit = crit }
end

return Damage
