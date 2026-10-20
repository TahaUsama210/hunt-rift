--!strict
-- Body plan for Hunt Master Odra at the Hunting Board: tall and lean, a wide-brimmed hunter's
-- hat with a big amber crest feather, a fur mantle over a forest-green tunic, a long cloak,
-- a spear on the back and a sealed contract in hand. The quest giver, so the camp also puts a
-- bouncing "!" over the hat. Same format as the monster rigs. Faces -Z, feet on y = 0.

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
	jointAt = { 0, 3.0, 0 },
	shape = "block",
	size = { 2.2, 0.9, 1.4 },
	pos = { 0, 3.0, 0 },
	color = "pants",
	tris = 500,
})
for _, side in { -1, 1 } do
	detail({
		segment = "Hips",
		shape = "block",
		size = { 0.9, 2.6, 1.0 },
		pos = { 0.55 * side, 1.4, 0 },
		color = "pants",
	})
	detail({
		segment = "Hips",
		shape = "block",
		size = { 1.05, 1.2, 1.35 },
		pos = { 0.55 * side, 0.6, -0.1 },
		color = "leather",
	})
end

segment({
	name = "Torso",
	attach = "Hips",
	joint = "Spine",
	jointAt = { 0, 3.2, 0 },
	shape = "ellipsoid",
	size = { 2.6, 3.0, 1.6 },
	pos = { 0, 4.4, 0 },
	color = "tunic",
	tris = 1300,
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 2.9, 4.8, 0.3 },
	pos = { 0, 3.4, 0.95 },
	rot = { 6, 0, 0 },
	color = "cloak",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 3.4, 1.1, 2.2 },
	pos = { 0, 5.75, 0.05 },
	color = "fur",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 2.7, 0.45, 1.75 },
	pos = { 0, 3.35, 0 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.25, 0.5, 0.2 },
	pos = { 0, 5.0, -0.85 },
	color = "bone",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.2, 0.4, 0.18 },
	pos = { -0.35, 5.1, -0.82 },
	color = "bone",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.2, 0.4, 0.18 },
	pos = { 0.35, 5.1, -0.82 },
	color = "bone",
})
-- Spear across the back, point up over the right shoulder.
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.25, 6.5, 0.25 },
	pos = { 0.4, 5.0, 1.3 },
	rot = { 0, 0, -25 },
	color = "wood",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.4, 1.3, 0.4 },
	pos = { 2.02, 8.5, 1.3 },
	rot = { 0, 0, -25 },
	color = "bone",
})

segment({
	name = "Head",
	attach = "Torso",
	joint = "Neck",
	jointAt = { 0, 6.0, 0 },
	shape = "ellipsoid",
	size = { 2.2, 2.4, 2.2 },
	pos = { 0, 6.9, -0.05 },
	color = "skin",
	tris = 1400,
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 4.4, 0.35, 4.0 },
	pos = { 0, 7.75, 0 },
	rot = { -6, 0, 0 },
	color = "hat",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.3, 1.5, 2.2 },
	pos = { 0, 8.3, 0.1 },
	color = "hat",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.35, 0.4, 2.25 },
	pos = { 0, 7.95, 0.1 },
	color = "trim",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.5, 2.6, 1.0 },
	pos = { 0.9, 9.0, 0.6 },
	rot = { -20, 0, -25 },
	color = "feather",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.4, 1.8, 0.8 },
	pos = { 1.2, 8.6, 0.8 },
	rot = { -30, 0, -40 },
	color = "featherTip",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 1.7, 0.9, 0.9 },
	pos = { 0, 6.1, -0.6 },
	color = "hair",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.4, 0.6, 0.45 },
	pos = { 0, 6.75, -1.12 },
	color = "skin",
})
detail({
	segment = "Head",
	shape = "block",
	size = { 0.12, 0.7, 0.1 },
	pos = { 0.55, 6.85, -1.06 },
	rot = { 0, 0, 20 },
	color = "scar",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.42, 0.26, 0.15 },
		pos = { 0.42 * side, 7.0, -1.05 },
		color = "eye",
	})
	detail({
		segment = "Head",
		shape = "block",
		size = { 0.6, 0.16, 0.15 },
		pos = { 0.45 * side, 7.25, -1.02 },
		rot = { 0, 0, 10 * side },
		color = "hair",
	})
end

for _, side in { 1, -1 } do
	local name = if side == 1 then "ArmR" else "ArmL"
	segment({
		name = name,
		attach = "Torso",
		joint = if side == 1 then "ShoulderR" else "ShoulderL",
		jointAt = { 1.45 * side, 5.4, 0 },
		shape = "ellipsoid",
		size = { 0.85, 2.6, 0.85 },
		pos = { 1.65 * side, 4.3, 0 },
		rot = { 0, 0, -5 * side },
		color = "tunic",
		tris = 400,
	})
	detail({
		segment = name,
		shape = "block",
		size = { 0.95, 0.9, 0.95 },
		pos = { 1.7 * side, 3.4, 0 },
		color = "leather",
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 0.75, 0.75, 0.75 },
		pos = { 1.75 * side, 2.8, -0.05 },
		color = "skin",
	})
end
-- A sealed hunting contract in the right hand.
detail({
	segment = "ArmR",
	shape = "block",
	size = { 0.4, 0.4, 1.6 },
	pos = { 1.75, 2.8, -0.5 },
	color = "paper",
})
detail({
	segment = "ArmR",
	shape = "ellipsoid",
	size = { 0.35, 0.35, 0.12 },
	pos = { 1.75, 2.8, -1.32 },
	color = "seal",
})

return {
	hipHeight = 3.0,
	rootSize = { 1, 1, 1 },
	colors = {
		skin = { 176, 122, 88 },
		hair = { 52, 40, 34 },
		tunic = { 58, 92, 70 },
		cloak = { 34, 62, 52 },
		fur = { 214, 198, 170 },
		leather = { 92, 60, 40 },
		pants = { 60, 54, 48 },
		hat = { 78, 58, 42 },
		trim = { 242, 169, 59 },
		feather = { 232, 142, 38 },
		featherTip = { 60, 198, 184 },
		bone = { 240, 234, 218 },
		wood = { 120, 84, 52 },
		scar = { 150, 90, 80 },
		paper = { 236, 224, 190 },
		seal = { 200, 40, 50 },
		eye = { 24, 22, 20 },
	},
	glow = {},
	segments = segments,
	details = details,
	-- Named spots the camp hangs effects on (attachments on that segment).
	points = {
		Contract = { segment = "ArmR", pos = { 1.75, 2.8, -0.5 } },
	},
	idle = {
		breathe = 0.05,
		period = 3.8,
		waveWith = "ShoulderR",
	},
}
