--!strict
-- Monster decisions. Pure functions: positions are flat { x, z } tables, angles are degrees,
-- `now` is seconds and `roll` is a number in [0, 1), so tests can drive every choice.

local MonsterAI = {}

export type Flat = { x: number, z: number }

-- Degrees between where the monster faces and the direction to the target (0 to 180).
function MonsterAI.angleTo(facing: Flat, offset: Flat): number
	local lf = math.sqrt(facing.x ^ 2 + facing.z ^ 2)
	local lo = math.sqrt(offset.x ^ 2 + offset.z ^ 2)
	if lf == 0 or lo == 0 then
		return 0
	end
	local dot = (facing.x * offset.x + facing.z * offset.z) / (lf * lo)
	return math.deg(math.acos(math.clamp(dot, -1, 1)))
end

-- Index of the closest position within maxRange, or nil.
function MonsterAI.nearest(origin: Flat, positions: { Flat }, maxRange: number): number?
	local best, bestDist = nil, maxRange
	for i, p in positions do
		local d = math.sqrt((p.x - origin.x) ^ 2 + (p.z - origin.z) ^ 2)
		if d <= bestDist then
			best, bestDist = i, d
		end
	end
	return best
end

-- Picks an attack that is off cooldown and whose range and angle fit the target, weighted
-- by each attack's weight. readyAt maps attack name to the time it can be used again.
-- An attack with lostWith is gone once that part is in broken (popping a spore lantern).
function MonsterAI.pickAttack(
	ai: any,
	distance: number,
	angle: number,
	readyAt: { [string]: number },
	now: number,
	roll: number,
	broken: { [string]: boolean }?
): string?
	local names = {}
	for name in ai.attacks do
		table.insert(names, name)
	end
	table.sort(names)

	local options, total = {}, 0
	for _, name in names do
		local attack = ai.attacks[name]
		local ready = (readyAt[name] or 0) <= now
		local lost = attack.lostWith ~= nil and broken ~= nil and broken[attack.lostWith] == true
		local fits = distance <= attack.range
			and distance >= (attack.minRange or 0)
			and angle >= attack.minAngle
			and angle <= attack.maxAngle
		if ready and fits and not lost then
			table.insert(options, name)
			total += attack.weight
		end
	end
	local target = roll * total
	for _, name in options do
		target -= ai.attacks[name].weight
		if target < 0 then
			return name
		end
	end
	return options[#options]
end

-- Whether a target at this distance and angle is caught by the attack.
function MonsterAI.inHitArea(attack: any, distance: number, angle: number): boolean
	return distance <= attack.hitRange and angle <= attack.hitArc / 2
end

-- Seconds a non-attack action (flinch, topple) keeps the monster busy.
function MonsterAI.actionSeconds(timing: any): number
	return timing.windup + timing.active + (timing.down or 0) + timing.recovery
end

-- Seconds an attack keeps the monster busy, and when it can be used again.
function MonsterAI.attackTimes(attack: any, now: number): (number, number)
	local busyUntil = now + attack.windup + attack.active + attack.recovery
	return busyUntil, busyUntil + attack.cooldown
end

return MonsterAI
