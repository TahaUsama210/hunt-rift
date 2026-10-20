--!strict
-- Monster stats. Plain data only: no Roblox objects, so tests run without Studio.
-- hitzones: percent of raw damage each body part takes (100 = normal, 45 = armoured).
-- elementHitzones: percent of elemental damage each body part takes.
-- breakHp: damage a part must take before it breaks (nil = cannot break).
-- rig: body plan in Shared/Rigs. Monsters without one cannot be spawned yet.
-- ai: how it hunts. Speeds are studs per second, ranges are studs from the monster's middle,
-- angles are degrees either side of where it faces. Each attack is only picked when the target
-- is within range and between minAngle and maxAngle, then hits everyone within hitRange and
-- hitArc. windup is the warning, active is when it hurts, recovery is the opening to punish.

return {
	Cinderwing = {
		displayName = "Cinderwing",
		maxHp = 4200,
		hitzones = { head = 70, wing = 45, tail = 50, body = 40 },
		elementHitzones = {
			fire = { head = 0, wing = 0, tail = 0, body = 0 },
			water = { head = 20, wing = 15, tail = 15, body = 10 },
		},
		breakHp = { head = 300, wing = 250, tail = 400 },
		lootTable = "Cinderwing",
	},
	Thornjaw = {
		displayName = "Thornjaw",
		maxHp = 1800,
		hitzones = { head = 80, leg = 55, tail = 45, body = 50 },
		elementHitzones = {
			fire = { head = 25, leg = 20, tail = 15, body = 15 },
			water = { head = 10, leg = 10, tail = 5, body = 5 },
		},
		breakHp = { head = 150 },
		lootTable = "Thornjaw",
		rig = "Thornjaw",
		ai = {
			walkSpeed = 13,
			turnSpeed = 2.5, -- radians per second
			aggroRange = 140,
			stopDistance = 10,
			attacks = {
				bite = {
					damage = 24,
					minAngle = 0,
					maxAngle = 35,
					range = 13,
					hitRange = 15,
					hitArc = 50,
					lunge = 5,
					windup = 0.75,
					active = 0.25,
					recovery = 0.7,
					cooldown = 1.2,
					weight = 3,
				},
				tailSpin = {
					damage = 18,
					minAngle = 0,
					maxAngle = 180,
					range = 12,
					hitRange = 17,
					hitArc = 360,
					lunge = 0,
					windup = 0.9,
					active = 0.45,
					recovery = 0.9,
					cooldown = 5,
					weight = 1,
				},
			},
		},
	},
}
