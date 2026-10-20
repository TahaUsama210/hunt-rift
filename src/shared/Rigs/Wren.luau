--!strict
-- Body plan for Wren, who runs the Upgrade Table: a small, quick tinkerer with a big head,
-- a teal hair tuft, brass goggles with glowing lenses pushed up on her forehead, a mustard
-- work jacket and a wrench, and an upgrade stone that orbits her head. Same format as the
-- monster rigs. Faces -Z, feet on y = 0.

local segments = {}
local details = {}

local function segment(s: any)
	table.insert(segments, s)
end
local function detail(d: any)
	table.insert(details, d)
end

segment({
	name = "Hips",
	attach = "Root",
	jointAt = { 0, 2.0, 0 },
	shape = "block",
	size = { 2.0, 0.8, 1.4 },
	pos = { 0, 2.0, 0 },
	color = "pants",
	tris = 400,
})
for _, side in { -1, 1 } do
	detail({
		segment = "Hips",
		shape = "block",
		size = { 0.8, 1.6, 0.9 },
		pos = { 0.48 * side, 1.0, 0 },
		color = "pants",
	})
	detail({
		segment = "Hips",
		shape = "block",
		size = { 0.95, 0.6, 1.25 },
		pos = { 0.48 * side, 0.3, -0.12 },
		color = "boots",
	})
end

segment({
	name = "Torso",
	attach = "Hips",
	joint = "Spine",
	jointAt = { 0, 2.3, 0 },
	shape = "ellipsoid",
	size = { 2.3, 2.4, 1.7 },
	pos = { 0, 3.3, 0 },
	color = "jacket",
	tris = 1000,
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 2.2, 0.8, 1.8 },
	pos = { 0, 4.3, -0.05 },
	color = "scarf",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.5, 1.3, 0.2 },
	pos = { 0.5, 3.7, -0.9 },
	rot = { 0, 0, -10 },
	color = "scarf",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.25, 2.8, 0.2 },
	pos = { 0, 3.3, -0.85 },
	rot = { 0, 0, 40 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.9, 0.9, 0.5 },
	pos = { -1.2, 2.6, -0.1 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.35, 0.35, 0.15 },
	pos = { -1.2, 2.7, -0.38 },
	color = "brass",
})

segment({
	name = "Head",
	attach = "Torso",
	joint = "Neck",
	jointAt = { 0, 4.6, 0 },
	shape = "ellipsoid",
	size = { 2.8, 2.7, 2.6 },
	pos = { 0, 5.9, 0 },
	color = "skin",
	tris = 1500,
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 3.0, 1.8, 2.8 },
	pos = { 0, 6.8, 0.25 },
	color = "hair",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.5, 0.8, 0.9 },
	pos = { 0, 6.95, -0.95 },
	color = "hair",
})
detail({
	segment = "Head",
	shape = "wedge",
	size = { 0.6, 1.3, 1.4 },
	pos = { 0.3, 7.8, 0.2 },
	rot = { 0, 0, -20 },
	color = "hair",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 1.2, 1.4, 1.2 },
	pos = { 0, 6.4, 1.2 },
	color = "hair",
})
for _, side in { -1, 1 } do
	-- Goggles pushed up: a brass rim with a glowing lens.
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.95, 0.95, 0.4 },
		pos = { 0.55 * side, 6.8, -1.18 },
		color = "brass",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.7, 0.7, 0.3 },
		pos = { 0.55 * side, 6.8, -1.3 },
		color = "lens",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.45, 0.6, 0.15 },
		pos = { 0.5 * side, 5.85, -1.22 },
		color = "pupil",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.16, 0.16, 0.08 },
		pos = { 0.44 * side, 6.0, -1.3 },
		color = "white",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.5, 0.28, 0.1 },
		pos = { 0.9 * side, 5.45, -1.08 },
		color = "blush",
	})
end
detail({
	segment = "Head",
	shape = "block",
	size = { 3.0, 0.3, 0.3 },
	pos = { 0, 6.8, -1.0 },
	color = "leather",
})

for _, side in { 1, -1 } do
	local name = if side == 1 then "ArmR" else "ArmL"
	segment({
		name = name,
		attach = "Torso",
		joint = if side == 1 then "ShoulderR" else "ShoulderL",
		jointAt = { 1.25 * side, 4.2, 0 },
		shape = "ellipsoid",
		size = { 0.8, 1.9, 0.8 },
		pos = { 1.45 * side, 3.4, 0 },
		rot = { 0, 0, -6 * side },
		color = "jacket",
		tris = 350,
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 0.85, 0.8, 0.85 },
		pos = { 1.5 * side, 2.4, -0.05 },
		color = "leather",
	})
end
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.3, 1.6, 0.3 },
	pos = { 1.5, 2.3, -0.45 },
	color = "metal",
})
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.8, 0.35, 0.3 },
	pos = { 1.5, 3.05, -0.45 },
	color = "metal",
})

-- The upgrade stone circles her head (the Orbit joint spins on each player's screen).
segment({
	name = "Stone",
	attach = "Root",
	joint = "Orbit",
	jointAt = { 0, 6.6, 0 },
	shape = "ellipsoid",
	size = { 0.7, 0.9, 0.7 },
	pos = { 1.9, 6.6, -0.6 },
	color = "stone",
	tris = 200,
})

return {
	hipHeight = 2.0,
	rootSize = { 1, 1, 1 },
	colors = {
		skin = { 236, 188, 150 },
		hair = { 60, 198, 184 },
		jacket = { 201, 140, 58 },
		scarf = { 32, 120, 120 },
		leather = { 96, 64, 44 },
		pants = { 64, 70, 86 },
		boots = { 52, 44, 40 },
		brass = { 214, 170, 80 },
		lens = { 120, 230, 255 },
		stone = { 111, 211, 255 },
		metal = { 120, 126, 136 },
		pupil = { 20, 18, 20 },
		white = { 255, 255, 255 },
		blush = { 240, 140, 140 },
	},
	glow = { lens = true, stone = true },
	segments = segments,
	details = details,
	-- Named spots the camp hangs effects on (attachments on that segment).
	points = {
		Stone = { segment = "Stone", pos = { 1.9, 6.6, -0.6 } },
		Wrench = { segment = "ArmR", pos = { 1.5, 3.05, -0.45 } },
	},
	idle = {
		breathe = 0.06,
		period = 2.6,
		waveWith = "ShoulderL",
		-- Tinkers in front of her: small quick turns of the wrench.
		work = { joint = "ShoulderR", every = 1.2, raise = 55, strike = 40 },
		orbit = 70,
	},
}
