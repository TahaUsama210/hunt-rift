local T = require("./TestKit")
local MonsterAI = require("../src/shared/Rules/MonsterAI")
local Monsters = require("../src/shared/Config/Monsters")

local ai = Monsters.Thornjaw.ai

T.test("angle to a target in front, beside and behind", function()
	local facing = { x = 0, z = -1 }
	T.near(MonsterAI.angleTo(facing, { x = 0, z = -5 }), 0)
	T.near(MonsterAI.angleTo(facing, { x = 3, z = 0 }), 90)
	T.near(MonsterAI.angleTo(facing, { x = 0, z = 4 }), 180)
end)

T.test("nearest ignores targets out of range", function()
	local origin = { x = 0, z = 0 }
	T.equal(MonsterAI.nearest(origin, { { x = 50, z = 0 }, { x = 0, z = 20 } }, 30), 2)
	T.equal(MonsterAI.nearest(origin, { { x = 50, z = 0 } }, 30), nil)
end)

T.test("bite only for a target in front, tail spin covers the rest", function()
	T.equal(MonsterAI.pickAttack(ai, 8, 90, {}, 0, 0.0), "tailSpin")
	-- In front both fit: the roll picks by weight (bite 3, tailSpin 1).
	T.equal(MonsterAI.pickAttack(ai, 8, 10, {}, 0, 0.1), "bite")
	T.equal(MonsterAI.pickAttack(ai, 8, 10, {}, 0, 0.9), "tailSpin")
	T.equal(MonsterAI.pickAttack(ai, 40, 10, {}, 0, 0.1), nil, "too far for anything")
end)

T.test("attacks on cooldown are skipped", function()
	local readyAt = { tailSpin = 10 }
	T.equal(MonsterAI.pickAttack(ai, 8, 10, readyAt, 5, 0.9), "bite")
	T.equal(MonsterAI.pickAttack(ai, 8, 90, readyAt, 5, 0.5), nil)
	T.equal(MonsterAI.pickAttack(ai, 8, 90, readyAt, 10, 0.5), "tailSpin")
end)

T.test("a charge needs room, and a lost part takes its attack away", function()
	local puff = Monsters.Puffgourd.ai
	T.equal(MonsterAI.pickAttack(puff, 20, 10, {}, 0, 0.5), "rollCharge")
	T.equal(MonsterAI.pickAttack(puff, 8, 90, {}, 0, 0.0), "sporeBurst")
	T.equal(MonsterAI.pickAttack(puff, 8, 90, {}, 0, 0.0, { pod = true }), nil, "lanterns popped")
	-- Up close in front: chomp or spores, never the charge (it needs 14 studs).
	for _, roll in { 0.0, 0.3, 0.6, 0.99 } do
		local pick = MonsterAI.pickAttack(puff, 8, 10, {}, 0, roll)
		assert(pick == "chomp" or pick == "sporeBurst", `rolled {pick}`)
	end
end)

T.test("a stagger lasts its windup, strike, time down and recovery", function()
	T.near(MonsterAI.actionSeconds({ windup = 0.3, active = 0.5, down = 4, recovery = 0.8 }), 5.6)
	T.near(MonsterAI.actionSeconds({ windup = 0.1, active = 0.1, recovery = 0.6 }), 0.8)
end)

T.test("hit areas", function()
	T.equal(MonsterAI.inHitArea(ai.attacks.bite, 10, 20), true)
	T.equal(MonsterAI.inHitArea(ai.attacks.bite, 10, 60), false, "bite misses to the side")
	T.equal(MonsterAI.inHitArea(ai.attacks.tailSpin, 12, 170), true, "spin hits behind")
	T.equal(MonsterAI.inHitArea(ai.attacks.tailSpin, 30, 0), false)
end)

T.test("attack times add up", function()
	local busy, ready = MonsterAI.attackTimes(ai.attacks.bite, 100)
	T.near(busy, 100 + 0.75 + 0.25 + 0.7)
	T.near(ready, busy + 1.2)
end)

T.test("every monster's attacks have all their numbers", function()
	local fields = { "damage", "minAngle", "maxAngle", "range", "hitRange", "hitArc", "lunge" }
	local times = { "windup", "active", "recovery", "cooldown", "weight" }
	for id, monster in Monsters do
		if monster.ai then
			for name, attack in monster.ai.attacks do
				for _, f in fields do
					assert(type(attack[f]) == "number", `{id}.{name} is missing {f}`)
				end
				for _, f in times do
					assert(type(attack[f]) == "number" and attack[f] >= 0, `{id}.{name}.{f}`)
				end
				-- A sweep travels its lunge while hitting, so it reaches that much further.
				local reach = attack.hitRange + (if attack.sweep then attack.lunge else 0)
				assert(attack.range <= reach, `{id}.{name} picks targets it cannot hit`)
			end
		end
	end
end)
