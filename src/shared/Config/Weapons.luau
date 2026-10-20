--!strict
-- Weapon stats and their moves.
-- attack: raw power. affinity: crit chance in percent (negative = chance of a weak hit).
-- element/elementPower: elemental damage added on every hit.
-- moves: motion value per move, in percent of raw attack.
-- swings: how each move plays. input is the button (light = left click, heavy = E,
-- special = R), style is the arm motion, reach is studs from the player, the rest are seconds.

return {
	IronGreatSword = {
		displayName = "Iron Great Sword",
		attack = 480,
		affinity = 0,
		moves = { overhead = 48, wideSlash = 26, chargedSlash = 90 },
		swings = {
			wideSlash = {
				input = "light",
				style = "horizontal",
				windup = 0.3,
				active = 0.2,
				recovery = 0.35,
				reach = 9,
			},
			overhead = {
				input = "heavy",
				style = "vertical",
				windup = 0.5,
				active = 0.2,
				recovery = 0.5,
				reach = 10,
			},
			chargedSlash = {
				input = "special",
				style = "charged",
				windup = 1.2,
				active = 0.25,
				recovery = 0.8,
				reach = 11,
			},
		},
	},
	FlameLongSword = {
		displayName = "Flame Long Sword",
		attack = 330,
		affinity = 10,
		element = "fire",
		elementPower = 180,
		moves = { thrust = 14, overhead = 26, spinSlash = 40 },
		swings = {
			thrust = {
				input = "light",
				style = "thrust",
				windup = 0.15,
				active = 0.15,
				recovery = 0.2,
				reach = 9,
			},
			overhead = {
				input = "heavy",
				style = "vertical",
				windup = 0.3,
				active = 0.2,
				recovery = 0.3,
				reach = 8,
			},
			spinSlash = {
				input = "special",
				style = "horizontal",
				windup = 0.5,
				active = 0.3,
				recovery = 0.5,
				reach = 9,
			},
		},
	},
	WaterDualBlades = {
		displayName = "Water Dual Blades",
		attack = 210,
		affinity = 5,
		element = "water",
		elementPower = 240,
		moves = { slash = 12, bladeFlurry = 30 },
		swings = {
			slash = {
				input = "light",
				style = "horizontal",
				windup = 0.1,
				active = 0.15,
				recovery = 0.15,
				reach = 6,
			},
			bladeFlurry = {
				input = "heavy",
				style = "vertical",
				windup = 0.2,
				active = 0.3,
				recovery = 0.3,
				reach = 6,
			},
		},
	},
}
