--!strict
-- Body plan for Pell, the Quartermaster: a round, cheerful trader under a backpack taller
-- than he is (crates, a rolled purple bedroll, a pot and a glowing lantern), a purple knit cap
-- with a gold bobble, a curly moustache, and a gold coin to flip. Same format as the monster
-- rigs. Faces -Z, feet on y = 0.

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
	jointAt = { 0, 1.8, 0 },
	shape = "block",
	size = { 2.4, 0.8, 1.8 },
	pos = { 0, 1.8, 0 },
	color = "pants",
	tris = 400,
})
for _, side in { -1, 1 } do
	detail({
		segment = "Hips",
		shape = "block",
		size = { 0.95, 1.3, 1.05 },
		pos = { 0.6 * side, 0.95, 0 },
		color = "pants",
	})
	detail({
		segment = "Hips",
		shape = "block",
		size = { 1.1, 0.6, 1.4 },
		pos = { 0.6 * side, 0.3, -0.15 },
		color = "boots",
	})
end

segment({
	name = "Torso",
	attach = "Hips",
	joint = "Spine",
	jointAt = { 0, 2.1, 0 },
	shape = "ellipsoid",
	size = { 3.4, 3.0, 3.0 },
	pos = { 0, 3.4, -0.1 },
	color = "vest",
	tris = 1600,
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 1.2, 2.0, 0.4 },
	pos = { 0, 3.5, -1.5 },
	color = "shirt",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 3.45, 0.5, 3.05 },
	pos = { 0, 2.9, -0.1 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.8, 0.9, 0.7 },
	pos = { 1.1, 2.6, -1.3 },
	color = "leather",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 0.5, 0.25, 0.5 },
	pos = { 1.1, 3.1, -1.3 },
	color = "gold",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Torso",
		shape = "block",
		size = { 0.3, 1.8, 0.15 },
		pos = { 0.9 * side, 4.0, -1.3 },
		color = "leather",
	})
end
-- The pack: two crates, a bedroll on top, a pot and a lantern hanging off the side.
detail({
	segment = "Torso",
	shape = "block",
	size = { 3.0, 1.8, 1.8 },
	pos = { 0, 3.6, 2.0 },
	color = "wood",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 2.6, 1.6, 1.6 },
	pos = { 0.1, 5.3, 2.0 },
	rot = { 0, 8, 0 },
	color = "woodDark",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 3.2, 0.9, 0.9 },
	pos = { 0, 6.5, 2.0 },
	color = "cloth",
})
detail({
	segment = "Torso",
	shape = "ellipsoid",
	size = { 1.0, 0.9, 1.0 },
	pos = { -1.65, 4.4, 2.2 },
	color = "metal",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.6, 0.8, 0.6 },
	pos = { 1.75, 5.4, 2.0 },
	color = "lantern",
})
detail({
	segment = "Torso",
	shape = "block",
	size = { 0.75, 0.15, 0.75 },
	pos = { 1.75, 5.85, 2.0 },
	color = "metal",
})

segment({
	name = "Head",
	attach = "Torso",
	joint = "Neck",
	jointAt = { 0, 4.8, 0 },
	shape = "ellipsoid",
	size = { 2.5, 2.4, 2.4 },
	pos = { 0, 5.9, -0.2 },
	color = "skin",
	tris = 1300,
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.45, 1.3, 2.45 },
	pos = { 0, 6.85, -0.1 },
	color = "cloth",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.5, 0.4, 2.5 },
	pos = { 0, 6.45, -0.15 },
	color = "clothDark",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.65, 0.65, 0.65 },
	pos = { 0, 7.55, 0 },
	color = "gold",
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 0.7, 0.6, 0.6 },
	pos = { 0, 5.85, -1.35 },
	color = "nose",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.95, 0.4, 0.45 },
		pos = { 0.45 * side, 5.5, -1.25 },
		rot = { 0, 0, -18 * side },
		color = "hair",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.32, 0.4, 0.15 },
		pos = { 0.5 * side, 6.2, -1.2 },
		color = "pupil",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.12, 0.12, 0.08 },
		pos = { 0.46 * side, 6.3, -1.28 },
		color = "white",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.6, 0.3, 0.12 },
		pos = { 0.5 * side, 6.48, -1.15 },
		color = "hair",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.5, 0.3, 0.1 },
		pos = { 0.92 * side, 5.6, -1.05 },
		color = "blush",
	})
end

for _, side in { 1, -1 } do
	local name = if side == 1 then "ArmR" else "ArmL"
	segment({
		name = name,
		attach = "Torso",
		joint = if side == 1 then "ShoulderR" else "ShoulderL",
		jointAt = { 1.6 * side, 4.4, 0 },
		shape = "ellipsoid",
		size = { 0.9, 1.8, 0.9 },
		pos = { 1.9 * side, 3.7, -0.1 },
		rot = { 0, 0, 12 * side },
		color = "shirt",
		tris = 350,
	})
	detail({
		segment = name,
		shape = "ellipsoid",
		size = { 0.8, 0.8, 0.8 },
		pos = { 2.05 * side, 2.8, -0.3 },
		color = "skin",
	})
end
-- The coin he keeps flipping.
detail({
	segment = "ArmR",
	shape = "ellipsoid",
	size = { 0.6, 0.6, 0.15 },
	pos = { 2.05, 3.25, -0.75 },
	color = "coin",
})

return {
	hipHeight = 1.8,
	rootSize = { 1, 1, 1 },
	colors = {
		skin = { 228, 176, 136 },
		nose = { 232, 150, 120 },
		hair = { 112, 72, 48 },
		vest = { 123, 96, 214 },
		shirt = { 236, 226, 204 },
		cloth = { 160, 107, 255 },
		clothDark = { 104, 70, 190 },
		pants = { 72, 60, 52 },
		boots = { 52, 40, 32 },
		leather = { 96, 64, 44 },
		wood = { 150, 108, 64 },
		woodDark = { 120, 84, 52 },
		metal = { 90, 96, 104 },
		gold = { 255, 194, 74 },
		coin = { 255, 205, 90 },
		lantern = { 255, 200, 110 },
		pupil = { 20, 18, 20 },
		white = { 255, 255, 255 },
		blush = { 240, 140, 140 },
	},
	glow = { coin = true, lantern = true },
	segments = segments,
	details = details,
	-- Named spots the camp hangs effects on (attachments on that segment).
	points = {
		Coin = { segment = "ArmR", pos = { 2.05, 3.25, -0.75 } },
		Lantern = { segment = "Torso", pos = { 1.75, 5.4, 2.0 } },
	},
	idle = {
		breathe = 0.1,
		period = 2.8,
		waveWith = "ShoulderL",
		-- Flicks the coin up every few seconds; it glints at the top.
		work = { joint = "ShoulderR", every = 4, raise = 70, strike = 20, at = "Coin" },
	},
}
