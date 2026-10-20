--!strict
-- Visual effects for Rift Camp: particle recipes, glow and the camp's lighting. Tuning the
-- look means changing these numbers. Why these effects and these values: research/vfx.md in
-- the project files (bloom on neon, warm dusk light, slow twinkles, bursts on reward moments,
-- nothing flashing faster than about once a second).
--
-- Textures are Roblox's built-in particle images, so nothing needs uploading. Swap any of them
-- for an uploaded "rbxassetid://..." image later and every effect using it follows.
-- Number ranges are { min, max }; curves are { { time 0..1, value }, ... } from 0 to 1.

local textures = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	sparks = "rbxasset://textures/particles/fire_sparks_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
}

export type Recipe = {
	texture: string,
	color: { number }?, -- left out: the caller's color (a portal's, a station's)
	rate: number, -- per second; 0 for burst-only emitters
	burst: number?, -- particles per burst when the client fires it
	lifetime: { number },
	speed: { number },
	size: { { number } },
	transparency: { { number } },
	spread: { number }?,
	acceleration: { number }?,
	drag: number?,
	rotSpeed: { number }?,
	brightness: number?,
	lightEmission: number?,
	zOffset: number?,
	squash: { { number } }?,
	shape: string?, -- Box, Sphere, Cylinder or Disc
	shapeStyle: string?, -- Volume or Surface
	shapeInOut: string?, -- Outward, Inward or InAndOut
	direction: string?, -- Top, Bottom, Front, Back, Left or Right
	velocityParallel: boolean?, -- particles stretch along their motion (sparks)
	lockedToPart: boolean?,
}

local recipes: { [string]: Recipe } = {
	-- Biome-colored sparks streaming from a portal's rim into its middle.
	portalVortex = {
		texture = textures.sparkle,
		rate = 16,
		lifetime = { 1.2, 2 },
		speed = { 1.5, 3 },
		size = { { 0, 0.5 }, { 1, 0 } },
		transparency = { { 0, 1 }, { 0.2, 0.15 }, { 1, 1 } },
		drag = 0.4,
		rotSpeed = { 90, 180 },
		brightness = 3,
		lightEmission = 1,
		zOffset = 1.5,
		shape = "Disc",
		shapeStyle = "Surface",
		shapeInOut = "Inward",
	},
	-- Motes drifting up off an open portal's pad.
	portalMotes = {
		texture = textures.sparkle,
		rate = 8,
		lifetime = { 1.5, 2.5 },
		speed = { 1.5, 3.5 },
		size = { { 0, 0 }, { 0.2, 0.35 }, { 1, 0 } },
		transparency = { { 0, 0.3 }, { 1, 1 } },
		acceleration = { 0, 2, 0 },
		drag = 0.5,
		brightness = 2.5,
		lightEmission = 1,
		direction = "Right",
	},
	-- Fireflies over the plaza: a slow twinkle, about once a second at most.
	fireflies = {
		texture = textures.sparkle,
		color = { 255, 226, 120 },
		rate = 5,
		lifetime = { 5, 8 },
		speed = { 0.2, 0.6 },
		size = { { 0, 0 }, { 0.15, 0.24 }, { 0.85, 0.24 }, { 1, 0 } },
		transparency = {
			{ 0, 1 },
			{ 0.15, 0.1 },
			{ 0.35, 0.6 },
			{ 0.55, 0.05 },
			{ 0.8, 0.5 },
			{ 1, 1 },
		},
		spread = { 180, 180 },
		acceleration = { 0, 0.15, 0 },
		drag = 0.6,
		rotSpeed = { -20, 20 },
		brightness = 3,
		lightEmission = 1,
	},
	-- Brazier and forge flames.
	flame = {
		texture = textures.fire,
		color = { 255, 150, 60 },
		rate = 14,
		lifetime = { 0.5, 0.9 },
		speed = { 2, 4 },
		size = { { 0, 1.6 }, { 1, 0.3 } },
		transparency = { { 0, 0.2 }, { 1, 1 } },
		spread = { 12, 12 },
		acceleration = { 0, 3, 0 },
		rotSpeed = { -40, 40 },
		brightness = 4,
		lightEmission = 1,
	},
	-- Embers that rise off the flames and bloom.
	embers = {
		texture = textures.sparks,
		color = { 255, 140, 40 },
		rate = 4,
		lifetime = { 1, 2.2 },
		speed = { 2, 4 },
		size = { { 0, 0.18 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		spread = { 35, 35 },
		acceleration = { 0, 4, 0 },
		drag = 0.8,
		brightness = 20,
		lightEmission = 1,
		zOffset = 1,
		squash = { { 0, -3 }, { 0.32, -0.19 }, { 1, -0.5 } },
		velocityParallel = true,
	},
	-- Chimney smoke over the forge.
	smoke = {
		texture = textures.smoke,
		color = { 90, 84, 88 },
		rate = 2,
		lifetime = { 4, 6 },
		speed = { 2, 3 },
		size = { { 0, 1.5 }, { 1, 5 } },
		transparency = { { 0, 1 }, { 0.1, 0.55 }, { 0.8, 0.75 }, { 1, 1 } },
		spread = { 6, 6 },
		acceleration = { 0.6, 1.5, 0 },
		drag = 0.4,
		rotSpeed = { -10, 10 },
		lightEmission = 0.05,
	},
	-- Sparks off the anvil each time Brannoc's hammer lands.
	anvil = {
		texture = textures.sparks,
		color = { 255, 170, 60 },
		rate = 0,
		burst = 24,
		lifetime = { 0.3, 0.7 },
		speed = { 10, 18 },
		size = { { 0, 0.22 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		spread = { 70, 70 },
		acceleration = { 0, -35, 0 },
		drag = 2,
		brightness = 20,
		lightEmission = 1,
		squash = { { 0, -2 }, { 1, -0.5 } },
		velocityParallel = true,
	},
	-- A glint when Pell flips his coin.
	glint = {
		texture = textures.sparkle,
		color = { 255, 214, 110 },
		rate = 0,
		burst = 6,
		lifetime = { 0.4, 0.7 },
		speed = { 2, 4 },
		size = { { 0, 0.5 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		spread = { 180, 180 },
		drag = 3,
		brightness = 4,
		lightEmission = 1,
	},
	-- A trail of sparkles behind something that moves (Wren's stone, Ama's wisps).
	trail = {
		texture = textures.sparkle,
		rate = 10,
		lifetime = { 0.5, 0.9 },
		speed = { 0.2, 0.6 },
		size = { { 0, 0.3 }, { 1, 0 } },
		transparency = { { 0, 0.2 }, { 1, 1 } },
		spread = { 180, 180 },
		brightness = 3,
		lightEmission = 1,
	},
	-- Magic dust rising around the featured egg and the upgrade runes.
	magicDust = {
		texture = textures.sparkle,
		rate = 8,
		lifetime = { 1.5, 2.5 },
		speed = { 0.3, 0.8 },
		size = { { 0, 0.3 }, { 1, 0 } },
		transparency = { { 0, 0.2 }, { 1, 1 } },
		acceleration = { 0, 1.2, 0 },
		drag = 1,
		brightness = 2,
		lightEmission = 1,
		shape = "Sphere",
		shapeStyle = "Surface",
		shapeInOut = "Outward",
	},
}

return {
	textures = textures,
	recipes = recipes,

	-- A soft column of light over an open portal (a Beam with no texture is a solid strip).
	portalPillar = {
		height = 40,
		width0 = 6,
		width1 = 1.5,
		transparency = { { 0, 0.35 }, { 1, 1 } },
	},
	-- Lights: range in studs, brightness. Lights flicker on each player's screen.
	lights = {
		portal = { range = 20, brightness = 2 },
		brazier = { range = 16, brightness = 1.6, color = { 255, 170, 90 } },
		forge = { range = 18, brightness = 2.2, color = { 255, 130, 50 } },
		lantern = { range = 12, brightness = 1.2, color = { 255, 205, 130 } },
		egg = { range = 14, brightness = 1.8 },
	},
	-- How fast things turn on each screen, in degrees per second.
	spin = { portalRing = 10, runes = 35, spireShards = 25, crystals = 15 },

	-- Camp lighting on each player's screen while they are in camp: a warm, magic dusk with
	-- bloom so neon and sparks glow. Leaving camp restores the hunting ground's lighting.
	camp = {
		clockTime = 17.8,
		brightness = 2,
		exposure = 0.2,
		ambient = { 70, 58, 72 },
		outdoorAmbient = { 150, 128, 165 },
		atmosphere = {
			density = 0.3,
			haze = 1.6,
			glare = 0.35,
			color = { 255, 178, 128 },
			decay = { 106, 90, 140 },
		},
		bloom = { intensity = 0.7, size = 28, threshold = 0.9 },
		colorCorrection = { contrast = 0.06, saturation = 0.12, tint = { 255, 246, 238 } },
		sunRays = { intensity = 0.04, spread = 0.3 },
	},
}
