--!strict
-- Body plan for Brannoc, the blacksmith: a barrel-chested smith with a braided ember beard,
-- a leather apron, huge forearms with gold bracers, and a hammer whose face glows from the
-- forge. Same format as the monster rigs (see Thornjaw), so the Blender mesh script can build
-- him too. Faces -Z, feet on y = 0. NPC segments have no hitzone: they cannot be hit.

local segments = {}
local details = {}

local function segment(s: any)
	table.insert(segments, s)
end
local function detail(d: any)
	table.insert(details, d)
end

-- Hips and legs ---------------------------------------------------------------------------
segment({
	name = "Hips",
	attach = "Root",
	jointAt = { 0, 2.6, 0 },
	shape = "block",
	size = { 2.8, 1.0, 1.9 },
	pos = { 0, 2.6, 0 },
	color = "pants",
	tris = 500,
})
for _, side in { -1, 1 } do
	detail({
		segment = "Hips",
		shape = "block",
		size = { 1.15, 2.0, 1.25 },
		pos = { 0.72 * side, 1.3, 0 },
		color = "pants",
	})
	detail({
		segment = "Hips",
		shape = "block",
		size = { 1.35, 0.7, 1.7 },
		pos = { 0.72 * side, 0.35, -0.15 },
		color = "boots",
	})
end

-- Torso -----------------------------------------------------------------------------------
segment({
	name = "Torso",
	attach = "Hips",
	joint = "Spine",
	jointAt = { 0, 3.0, 0 },
	shape = "ellipsoid",
	size = { 3.8, 3.4, 2.6 },
	pos = { 0, 4.3, 0 },
	color = "shirt",
	tris = 1300,
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 2.6, 3.0, 0.25 },
	pos = { 0, 3.1, -1.25 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 3.3, 0.5, 2.4 },
	pos = { 0, 3.0, 0 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.7, 0.55, 0.2 },
	pos = { 0, 3.0, -1.32 },
	color = "gold",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 1.6, 0.8, 1.4 },
	pos = { 0, 5.9, 0 },
	color = "skin",
})
-- Apron pocket with tongs sticking out.
detail({
	segment = "Torso",
	shape = "block",
	size = { 1.2, 0.8, 0.2 },
	pos = { 0.6, 2.4, -1.38 },
	color = "leatherDark",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.18, 1.1, 0.18 },
	pos = { 0.45, 2.9, -1.42 },
	rot = { 0, 0, 8 },
	color = "metal",
})

-- Head ------------------------------------------------------------------------------------
segment({
	name = "Head",
	attach = "Torso",
	joint = "Neck",
	jointAt = { 0, 6.0, 0 },
	shape = "ellipsoid",
	size = { 2.3, 2.4, 2.3 },
	pos = { 0, 7.0, -0.1 },
	color = "skin",
	tris = 1400,
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.1, 2.2, 1.3 },
	pos = { 0, 6.25, -0.8 },
	color = "beard",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.7, 1.3, 0.7 },
	pos = { 0, 5.0, -1.15 },
	color = "beard",
})
detail({
	segment = "Head",
	shape = "block",
	size = { 0.8, 0.25, 0.8 },
	pos = { 0, 4.55, -1.2 },
	color = "gold",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 1.7, 0.5, 0.55 },
	pos = { 0, 6.85, -1.15 },
	color = "beard",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.55, 0.6, 0.5 },
	pos = { 0, 7.2, -1.22 },
	color = "skin",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.32, 0.42, 0.15 },
		pos = { 0.42 * side, 7.5, -1.08 },
		color = "pupil",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.12, 0.12, 0.08 },
		pos = { 0.38 * side, 7.6, -1.16 },
		color = "white",
	})
	detail({
		segment = "Head",
		shape = "block",
		size = { 0.7, 0.2, 0.15 },
		pos = { 0.45 * side, 7.86, -1.04 },
		rot = { 0, 0, -14 * side },
		color = "beard",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.35, 0.6, 0.5 },
		pos = { 1.15 * side, 7.0, 0 },
		color = "skin",
	})
end

-- Arms (the right one swings the hammer) ---------------------------------------------------
for _, side in { 1, -1 } do
	local name = if side == 1 then "ArmR" else "ArmL"
	segment({
		name = name,
		attach = "Torso",
		joint = if side == 1 then "ShoulderR" else "ShoulderL",
		jointAt = { 2.1 * side, 5.3, 0 },
		shape = "ellipsoid",
		size = { 1.3, 2.2, 1.3 },
		pos = { 2.35 * side, 4.6, 0 },
		rot = { 0, 0, -8 * side },
		color = "shirt",
		tris = 450,
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 1.5, 2.0, 1.5 },
		pos = { 2.55 * side, 3.2, -0.1 },
		color = "skin",
	})
	detail({
		segment = name,
		shape = "block",
		size = { 1.55, 0.8, 1.55 },
		pos = { 2.55 * side, 2.9, -0.1 },
		color = "gold",
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 1.3, 1.2, 1.3 },
		pos = { 2.6 * side, 2.0, -0.2 },
		color = "skin",
	})
end
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.35, 3.4, 0.35 },
	pos = { 2.6, 2.8, -0.75 },
	color = "wood",
})
detail({
	segment = "ArmR",
	shape = "block",
	size = { 1.7, 1.0, 1.0 },
	pos = { 2.6, 4.5, -0.75 },
	color = "metal",
})
detail({
	segment = "ArmR",
	shape = "block",
	size = { 1.72, 0.3, 1.02 },
	pos = { 2.6, 4.5, -0.75 },
	color = "ember",
})

return {
	hipHeight = 2.6,
	rootSize = { 1, 1, 1 },
	colors = {
		skin = { 205, 145, 105 },
		beard = { 232, 110, 40 },
		shirt = { 150, 58, 40 },
		leather = { 92, 60, 40 },
		leatherDark = { 62, 40, 28 },
		pants = { 70, 58, 50 },
		boots = { 44, 34, 28 },
		gold = { 242, 169, 59 },
		metal = { 70, 74, 82 },
		ember = { 255, 120, 40 },
		wood = { 120, 84, 52 },
		pupil = { 20, 18, 20 },
		white = { 255, 255, 255 },
	},
	glow = { ember = true },
	segments = segments,
	details = details,
	-- Named spots the camp hangs effects on (attachments on that segment).
	points = {
		Hammer = { segment = "ArmR", pos = { 2.6, 4.5, -0.75 } },
	},
	-- How the camp animates him on each player's screen (client/CampLife).
	idle = {
		breathe = 0.08,
		period = 3.4,
		waveWith = "ShoulderL",
		-- Brings the hammer down on the anvil every few seconds; at = where the sparks fly.
		work = { joint = "ShoulderR", every = 3.5, raise = 115, strike = 35, at = "AnvilSparks" },
	},
}
