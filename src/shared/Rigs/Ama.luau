--!strict
-- Body plan for Nestkeeper Ama at the Nest Spire: a hooded figure in a plum robe trimmed with
-- glowing rift magenta, two bright eyes in the shadow of the hood, a crook staff with an
-- egg-shaped lantern, and three wisps circling. Floats a little off the ground. Same format as
-- the monster rigs. Faces -Z; the robe's hem hangs just above y = 0.

local segments = {}
local details = {}

local function segment(s: any)
	table.insert(segments, s)
end
local function detail(d: any)
	table.insert(details, d)
end

-- The robe floats: the Float joint bobs everything above it.
segment({
	name = "Robe",
	attach = "Root",
	joint = "Float",
	jointAt = { 0, 3.0, 0 },
	shape = "ellipsoid",
	size = { 3.0, 2.6, 3.0 },
	pos = { 0, 2.4, 0 },
	color = "robe",
	tris = 700,
})
detail({
	segment = "Robe",
	shape = "ellipsoid",
	size = { 3.6, 1.2, 3.6 },
	pos = { 0, 1.4, 0 },
	color = "robe",
})
detail({
	segment = "Robe",
	shape = "ellipsoid",
	size = { 3.7, 0.4, 3.7 },
	pos = { 0, 0.95, 0 },
	color = "trim",
})

segment({
	name = "Torso",
	attach = "Robe",
	joint = "Spine",
	jointAt = { 0, 3.4, 0 },
	shape = "ellipsoid",
	size = { 2.4, 2.6, 1.9 },
	pos = { 0, 4.2, 0 },
	color = "robe",
	tris = 1000,
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 2.45, 0.45, 1.95 },
	pos = { 0, 3.6, 0 },
	color = "gold",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 3.0, 1.0, 2.2 },
	pos = { 0, 5.2, 0 },
	color = "mantle",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.5, 0.7, 0.3 },
	pos = { 0, 4.6, -0.95 },
	color = "egg",
})

segment({
	name = "Head",
	attach = "Torso",
	joint = "Neck",
	jointAt = { 0, 5.5, 0 },
	shape = "ellipsoid",
	size = { 2.6, 2.9, 2.6 },
	pos = { 0, 6.5, 0.1 },
	color = "hood",
	tris = 1100,
})
-- A glowing rim around a dark face, and two bright eyes in it.
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.2, 2.4, 0.35 },
	pos = { 0, 6.35, -0.88 },
	color = "trim",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 1.8, 2.0, 0.6 },
	pos = { 0, 6.3, -1.0 },
	color = "shadow",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.9, 1.4, 0.9 },
	pos = { 0, 8.0, 0.5 },
	rot = { -25, 0, 0 },
	color = "hood",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.38, 0.24, 0.12 },
		pos = { 0.38 * side, 6.45, -1.26 },
		color = "eyes",
	})
end

for _, side in { 1, -1 } do
	local name = if side == 1 then "ArmR" else "ArmL"
	segment({
		name = name,
		attach = "Torso",
		joint = if side == 1 then "ShoulderR" else "ShoulderL",
		jointAt = { 1.3 * side, 5.2, 0 },
		shape = "ellipsoid",
		size = { 1.0, 2.4, 1.0 },
		pos = { 1.6 * side, 4.3, -0.1 },
		rot = { 0, 0, -10 * side },
		color = "robe",
		tris = 350,
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 1.1, 0.45, 1.1 },
		pos = { 1.75 * side, 3.25, -0.15 },
		color = "trim",
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 0.6, 0.6, 0.6 },
		pos = { 1.78 * side, 3.0, -0.3 },
		color = "gloves",
	})
end
-- Crook staff with the egg lantern hanging from its hook.
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.3, 7.0, 0.3 },
	pos = { 1.8, 3.3, -0.5 },
	color = "wood",
})
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.3, 0.3, 1.0 },
	pos = { 1.8, 6.85, -0.85 },
	color = "wood",
})
detail({
	segment = "ArmR",
	shape = "ellipsoid",
	size = { 0.6, 0.8, 0.6 },
	pos = { 1.8, 6.2, -1.25 },
	color = "egg",
})

-- Three wisps circling her (the Orbit joint spins on each player's screen).
segment({
	name = "Wisps",
	attach = "Root",
	joint = "Orbit",
	jointAt = { 0, 5.5, 0 },
	shape = "ellipsoid",
	size = { 0.45, 0.45, 0.45 },
	pos = { 2.4, 5.5, 0 },
	color = "wisp",
	tris = 200,
})
detail({
	segment = "Wisps",
	shape = "ellipsoid",
	size = { 0.35, 0.35, 0.35 },
	pos = { -1.2, 6.0, 2.1 },
	color = "wisp",
})
detail({
	segment = "Wisps",
	shape = "ellipsoid",
	size = { 0.4, 0.4, 0.4 },
	pos = { -1.2, 5.0, -2.1 },
	color = "wisp",
})

return {
	hipHeight = 3.0,
	rootSize = { 1, 1, 1 },
	colors = {
		robe = { 92, 40, 110 },
		mantle = { 52, 24, 64 },
		hood = { 110, 48, 128 },
		trim = { 224, 91, 208 },
		shadow = { 12, 8, 16 },
		eyes = { 255, 200, 250 },
		egg = { 255, 170, 240 },
		wisp = { 224, 140, 255 },
		gold = { 242, 169, 59 },
		gloves = { 120, 90, 140 },
		wood = { 90, 64, 52 },
	},
	glow = { trim = true, eyes = true, egg = true, wisp = true },
	segments = segments,
	details = details,
	-- Named spots the camp hangs effects on (attachments on that segment).
	points = {
		Lantern = { segment = "ArmR", pos = { 1.8, 6.2, -1.25 } },
		Wisp = { segment = "Wisps", pos = { 2.4, 5.5, 0 } },
	},
	idle = {
		breathe = 0.04,
		period = 4,
		-- Bobs up and down in the air.
		float = 0.35,
		waveWith = "ShoulderL",
		orbit = 45,
	},
}
