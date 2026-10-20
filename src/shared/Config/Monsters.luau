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
-- Optional per attack: minRange (only from at least this far), sweep (hits along its whole
-- lunge, like a rolling charge), lostWith (the attack is gone once that part breaks).
-- breakActions: the stagger played when a part breaks (an animation in the rig; flinch if unset).

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
	-- Beginner monster. Its lantern crown ("pod") is the weak spot: popping it stops the spore
	-- burst and flips it onto its back for a long damage window.
	Puffgourd = {
		displayName = "Puffgourd",
		maxHp = 1200,
		hitzones = { head = 70, body = 55, leg = 50, pod = 95 },
		elementHitzones = {
			fire = { head = 25, body = 20, leg = 15, pod = 35 },
			thunder = { head = 25, body = 20, leg = 15, pod = 30 },
			water = { head = 5, body = 5, leg = 5, pod = 10 },
		},
		breakHp = { pod = 120, head = 200 },
		lootTable = "Puffgourd",
		rig = "Puffgourd",
		ai = {
			walkSpeed = 9,
			turnSpeed = 2,
			aggroRange = 60,
			stopDistance = 8,
			breakActions = { pod = "topple" },
			attacks = {
				chomp = {
					damage = 12,
					minAngle = 0,
					maxAngle = 35,
					range = 10,
					hitRange = 11,
					hitArc = 70,
					lunge = 3,
					windup = 0.8,
					active = 0.25,
					recovery = 0.8,
					cooldown = 1.5,
					weight = 3,
				},
				rollCharge = {
					damage = 18,
					minAngle = 0,
					maxAngle = 25,
					minRange = 14,
					range = 28,
					hitRange = 7,
					hitArc = 360,
					lunge = 22,
					sweep = true,
					windup = 1.0,
					active = 1.1,
					recovery = 1.0,
					cooldown = 6,
					weight = 2,
				},
				sporeBurst = {
					damage = 14,
					minAngle = 0,
					maxAngle = 180,
					range = 10,
					hitRange = 12,
					hitArc = 360,
					lunge = 0,
					lostWith = "pod",
					windup = 1.1,
					active = 0.4,
					recovery = 0.9,
					cooldown = 6,
					weight = 2,
				},
			},
		},
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
			aggroRange = 90,
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
