--!strict
-- Body plan for the Thornjaw: an original teal raptor with an amber head crest.
-- Plain data only, so Lune tests and the Blender mesh script can read it too.
--
-- Space: studs, the monster faces -Z, feet on y = 0. rot is degrees (x = nose up, y = turn
-- left, z = roll). Segments are the moving pieces: each one with a joint gets a Motor6D at
-- jointAt so it can animate, one without is welded. Details are decoration welded to a segment;
-- when the imported mesh is used they are already baked into that segment's mesh.
-- hitzone matches Config/Monsters hitzones. breaksWith hides the segment when that part breaks.
-- tris is the triangle budget for the segment's mesh (the whole monster is about 6,000).

export type Shape = "ellipsoid" | "block" | "wedge"
export type Segment = {
	name: string,
	attach: string,
	joint: string?,
	jointAt: { number },
	shape: Shape,
	size: { number },
	pos: { number },
	rot: { number }?,
	color: string,
	hitzone: string,
	breaksWith: string?,
	tris: number,
}
export type Detail = {
	segment: string,
	shape: Shape,
	size: { number },
	pos: { number },
	rot: { number }?,
	color: string,
}
export type PoseValues = {
	pitch: number?,
	yaw: number?,
	roll: number?,
	x: number?,
	y: number?,
	z: number?,
}
export type Pose = { [string]: PoseValues }
export type Animation = {
	windup: Pose,
	strike: Pose,
	-- Where recovery starts from when strike ends somewhere awkward (after a full spin).
	recoverFrom: Pose?,
	-- Seconds for actions that are not attacks (attacks take theirs from Config/Monsters).
	timing: { windup: number, active: number, recovery: number }?,
	-- Keep the strike pose when finished instead of returning to rest.
	hold: boolean?,
}

local segments: { Segment } = {}
local details: { Detail } = {}

local function segment(s: Segment)
	table.insert(segments, s)
end

local function detail(d: Detail)
	table.insert(details, d)
end

-- Height of the body's top surface at (x, z), so spots and spikes sit on the skin.
local BODY_CENTER, BODY_HALF = { 0, 5.3, 0 }, { 2.8, 2.3, 4.7 }
local function bodyTop(x: number, z: number): number
	local k = 1 - (x / BODY_HALF[1]) ^ 2 - ((z - BODY_CENTER[3]) / BODY_HALF[3]) ^ 2
	return BODY_CENTER[2] + BODY_HALF[2] * math.sqrt(math.max(0, k))
end

-- Body ------------------------------------------------------------------------------------
segment({
	name = "Body",
	attach = "Root",
	joint = "Spine",
	jointAt = { 0, 5, 0 },
	shape = "ellipsoid",
	size = { BODY_HALF[1] * 2, BODY_HALF[2] * 2, BODY_HALF[3] * 2 },
	pos = BODY_CENTER,
	color = "skin",
	hitzone = "body",
	tris = 1150,
})
detail({
	segment = "Body",
	shape = "ellipsoid",
	size = { 4.6, 3.0, 7.8 },
	pos = { 0, 4.3, 0.2 },
	color = "belly",
})
-- Shoulders and haunches, so the legs grow out of the body.
for _, side in { -1, 1 } do
	detail({
		segment = "Body",
		shape = "ellipsoid",
		size = { 2.4, 3.4, 3.0 },
		pos = { 2.0 * side, 5.0, -2.8 },
		color = "skin",
	})
	detail({
		segment = "Body",
		shape = "ellipsoid",
		size = { 2.8, 3.8, 3.8 },
		pos = { 2.0 * side, 5.2, 2.7 },
		color = "skin",
	})
end
for _, z in { -2.8, -1.0, 0.8, 2.6 } do
	for _, side in { -1, 1 } do
		local x = 1.45 * side
		detail({
			segment = "Body",
			shape = "ellipsoid",
			size = { 1.4, 0.5, 1.3 },
			pos = { x, bodyTop(x, z) - 0.12, z },
			rot = { 0, 0, -28 * side },
			color = "stripe",
		})
	end
end
for i = 0, 5 do
	local z = -3.4 + i * 1.35
	local h = 1.7 - math.abs(z) * 0.18
	detail({
		segment = "Body",
		shape = "wedge",
		size = { 0.35, h, 1.3 },
		pos = { 0, bodyTop(0, z) + h / 2 - 0.35, z },
		rot = { -12, 0, 0 },
		color = "crest",
	})
end

-- Neck and head ---------------------------------------------------------------------------
segment({
	name = "Neck",
	attach = "Body",
	joint = "Neck",
	jointAt = { 0, 6.2, -4.0 },
	shape = "ellipsoid",
	size = { 3.0, 3.0, 5.0 },
	pos = { 0, 6.9, -5.8 },
	rot = { 22, 0, 0 },
	color = "skin",
	hitzone = "body",
	tris = 400,
})
detail({
	segment = "Neck",
	shape = "ellipsoid",
	size = { 2.0, 1.4, 3.6 },
	pos = { 0, 6.25, -6.0 },
	rot = { 22, 0, 0 },
	color = "belly",
})
for i = 0, 2 do
	detail({
		segment = "Neck",
		shape = "wedge",
		size = { 0.3, 1.0, 1.0 },
		pos = { 0, 8.25 + i * 0.35, -4.9 - i * 0.9 },
		rot = { -10, 0, 0 },
		color = "stripe",
	})
end

segment({
	name = "Head",
	attach = "Neck",
	joint = "Head",
	jointAt = { 0, 7.5, -7.6 },
	shape = "ellipsoid",
	size = { 3.4, 2.7, 4.6 },
	pos = { 0, 7.9, -9.2 },
	rot = { 8, 0, 0 },
	color = "skin",
	hitzone = "head",
	tris = 1100,
})
detail({
	segment = "Head",
	shape = "ellipsoid",
	size = { 2.6, 1.7, 3.4 },
	pos = { 0, 7.5, -11.2 },
	color = "skin",
})
for _, side in { -1, 1 } do
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.75, 0.75, 0.75 },
		pos = { 1.3 * side, 8.35, -9.9 },
		color = "eye",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.2, 0.6, 0.28 },
		pos = { 1.6 * side, 8.38, -10.0 },
		color = "pupil",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.25, 0.2, 0.45 },
		pos = { 0.55 * side, 7.9, -12.2 },
		rot = { 10, 0, 0 },
		color = "pupil",
	})
	detail({
		segment = "Head",
		shape = "ellipsoid",
		size = { 0.8, 0.45, 1.5 },
		pos = { 1.05 * side, 8.75, -9.6 },
		rot = { 0, 0, -15 * side },
		color = "stripe",
	})
	for i, z in { -10.1, -10.8, -11.5, -12.1 } do
		detail({
			segment = "Head",
			shape = "wedge",
			size = { 0.2, 0.5 - i * 0.05, 0.28 },
			pos = { (0.95 - i * 0.07) * side, 6.85, z },
			rot = { 180, 0, 0 },
			color = "bone",
		})
	end
end

segment({
	name = "Jaw",
	attach = "Head",
	joint = "Jaw",
	jointAt = { 0, 7.0, -8.4 },
	shape = "ellipsoid",
	size = { 2.3, 0.9, 4.2 },
	pos = { 0, 6.75, -10.3 },
	color = "belly",
	hitzone = "head",
	tris = 450,
})
for _, side in { -1, 1 } do
	for i, z in { -10.4, -11.1, -11.7 } do
		detail({
			segment = "Jaw",
			shape = "wedge",
			size = { 0.18, 0.4, 0.25 },
			pos = { (0.8 - i * 0.08) * side, 7.25, z },
			color = "bone",
		})
	end
end

-- The amber crest is what breaks off when the head breaks.
segment({
	name = "Crest",
	attach = "Head",
	jointAt = { 0, 9.0, -8.6 },
	shape = "wedge",
	size = { 0.5, 1.9, 1.4 },
	pos = { 0, 9.6, -7.9 },
	rot = { -20, 0, 0 },
	color = "crest",
	hitzone = "head",
	breaksWith = "head",
	tris = 400,
})
for i = 0, 2 do
	detail({
		segment = "Crest",
		shape = "wedge",
		size = { 0.45, 1.2 - i * 0.25, 1.0 },
		pos = { 0, 9.05 - i * 0.05, -9.2 - i * 0.6 },
		rot = { -15, 0, 0 },
		color = "crest",
	})
end
for _, side in { -1, 1 } do
	detail({
		segment = "Crest",
		shape = "wedge",
		size = { 0.45, 1.7, 1.0 },
		pos = { 1.25 * side, 9.25, -7.9 },
		rot = { -35, 0, -25 * side },
		color = "crest",
	})
end

-- Legs ------------------------------------------------------------------------------------
local legs = {
	{ key = "FL", x = -2.5, z = -2.8, front = true },
	{ key = "FR", x = 2.5, z = -2.8, front = true },
	{ key = "BL", x = -2.65, z = 2.8, front = false },
	{ key = "BR", x = 2.65, z = 2.8, front = false },
}
for _, leg in legs do
	local x, z = leg.x, leg.z
	segment({
		name = "UpperLeg" .. leg.key,
		attach = "Body",
		joint = "Hip" .. leg.key,
		jointAt = { x, 5.0, z },
		shape = "ellipsoid",
		size = if leg.front then { 1.7, 3.8, 2.1 } else { 2.3, 4.2, 3.0 },
		pos = { x * 1.05, 3.9, z },
		rot = { if leg.front then -10 else 15, 0, 0 },
		color = "skin",
		hitzone = "leg",
		tris = 180,
	})
	segment({
		name = "LowerLeg" .. leg.key,
		attach = "UpperLeg" .. leg.key,
		joint = "Knee" .. leg.key,
		jointAt = { x * 1.05, 2.3, z },
		shape = "ellipsoid",
		size = if leg.front then { 1.1, 2.9, 1.2 } else { 1.3, 2.9, 1.4 },
		pos = { x * 1.05, 1.45, z + (if leg.front then -0.2 else 0.3) },
		rot = { if leg.front then 0 else -15, 0, 0 },
		color = "skin",
		hitzone = "leg",
		tris = 250,
	})
	detail({
		segment = "LowerLeg" .. leg.key,
		shape = "ellipsoid",
		size = { 1.5, 0.6, 2.2 },
		pos = { x * 1.05, 0.3, z - 0.5 },
		color = "stripe",
	})
	for _, dx in { -0.45, 0, 0.45 } do
		detail({
			segment = "LowerLeg" .. leg.key,
			shape = "wedge",
			size = { 0.24, 0.4, 0.7 },
			pos = { x * 1.05 + dx, 0.22, z - 1.75 },
			color = "bone",
		})
	end
end

-- Tail ------------------------------------------------------------------------------------
local tail = {
	{
		name = "TailA",
		attach = "Body",
		at = { 0, 5.7, 4.0 },
		size = { 3.6, 3.2, 6.4 },
		pos = { 0, 5.7, 6.5 },
		tris = 350,
	},
	{
		name = "TailB",
		attach = "TailA",
		at = { 0, 5.5, 8.8 },
		size = { 2.4, 2.2, 6.0 },
		pos = { 0, 5.4, 11.0 },
		tris = 250,
	},
	{
		name = "TailC",
		attach = "TailB",
		at = { 0, 5.3, 13.4 },
		size = { 1.4, 1.3, 5.4 },
		pos = { 0, 5.15, 15.4 },
		tris = 200,
	},
}
for _, t in tail do
	segment({
		name = t.name,
		attach = t.attach,
		joint = t.name,
		jointAt = t.at,
		shape = "ellipsoid",
		size = t.size,
		pos = t.pos,
		rot = { -4, 0, 0 },
		color = "skin",
		hitzone = "tail",
		tris = t.tris,
	})
	local top = t.pos[2] + t.size[2] / 2
	for _, dz in { -1.2, 0.6 } do
		local h = t.size[2] * 0.42
		detail({
			segment = t.name,
			shape = "wedge",
			size = { 0.3, h, 1.0 },
			pos = { 0, top + h / 2 - 0.3, t.pos[3] + dz },
			rot = { -18, 0, 0 },
			color = "crest",
		})
	end
	detail({
		segment = t.name,
		shape = "ellipsoid",
		size = { t.size[1] * 1.02, t.size[2] * 0.35, t.size[3] * 0.3 },
		pos = { 0, top - t.size[2] * 0.12, t.pos[3] - 0.3 },
		color = "stripe",
	})
end
detail({
	segment = "TailC",
	shape = "wedge",
	size = { 0.5, 0.8, 1.6 },
	pos = { 0, 5.2, 18.2 },
	rot = { 90, 0, 0 },
	color = "crest",
})

-- Animations ------------------------------------------------------------------------------
-- Pose values are degrees and studs added on top of the rest pose and walk cycle.
local animations: { [string]: Animation } = {
	bite = {
		windup = {
			Spine = { pitch = 8, z = 1.2 },
			Neck = { pitch = 28 },
			Head = { pitch = 18 },
			Jaw = { pitch = -42 },
		},
		strike = {
			Spine = { pitch = -6, z = -1.4 },
			Neck = { pitch = -22 },
			Head = { pitch = -14 },
			Jaw = { pitch = -3 },
		},
	},
	tailSpin = {
		windup = {
			Spine = { yaw = 40, y = -0.6 },
			Neck = { yaw = 15 },
			TailA = { yaw = -25 },
			TailB = { yaw = -25 },
			TailC = { yaw = -20 },
		},
		strike = {
			Spine = { yaw = 40 - 360, y = -0.3 },
			TailA = { yaw = 20 },
			TailB = { yaw = 25 },
			TailC = { yaw = 25 },
		},
		recoverFrom = {
			Spine = { yaw = 40, y = -0.3 },
			TailA = { yaw = 20 },
			TailB = { yaw = 25 },
			TailC = { yaw = 25 },
		},
	},
	flinch = {
		timing = { windup = 0.12, active = 0.1, recovery = 0.6 },
		windup = {
			Spine = { roll = 10, z = 0.6 },
			Neck = { pitch = 30, yaw = -15 },
			Head = { pitch = 20 },
			Jaw = { pitch = -35 },
		},
		strike = {
			Spine = { roll = 8, z = 0.5 },
			Neck = { pitch = 25, yaw = -12 },
			Head = { pitch = 15 },
			Jaw = { pitch = -25 },
		},
	},
	death = {
		timing = { windup = 0.5, active = 1.1, recovery = 0 },
		hold = true,
		windup = { Neck = { pitch = 35 }, Head = { pitch = 20 }, Jaw = { pitch = -45 } },
		strike = {
			Spine = { roll = 85, y = -2.4 },
			Neck = { pitch = -10, yaw = 20 },
			Head = { pitch = -15 },
			Jaw = { pitch = -25 },
			HipFL = { pitch = 25 },
			HipFR = { pitch = -15 },
			HipBL = { pitch = -20 },
			HipBR = { pitch = 10 },
			TailA = { yaw = 15 },
			TailB = { yaw = 15 },
		},
	},
}

return {
	-- Height of the root joint above the ground.
	hipHeight = 5,
	rootSize = { 2, 2, 2 },
	colors = {
		skin = { 46, 110, 98 },
		belly = { 222, 208, 168 },
		stripe = { 26, 60, 56 },
		crest = { 232, 142, 38 },
		eye = { 255, 196, 48 },
		pupil = { 18, 18, 20 },
		bone = { 240, 234, 218 },
	},
	-- Colors drawn with a glow in the parts version.
	glow = { eye = true },
	segments = segments,
	details = details,
	-- Walk cycle: degrees of leg swing and knee bend, and studs walked per full step.
	gait = { stride = 26, knee = 30, stepLength = 7, tailSway = 7, bob = 0.25 },
	animations = animations,
}
