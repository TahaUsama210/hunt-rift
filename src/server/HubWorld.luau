--!strict
-- Builds Rift Camp from Config/Hub out of plain parts: a floating island with the plaza, the
-- portal arc, the stations with their hunters and props, the Nest Spire and the spawn, plus
-- the effects from Config/Fx (particles, lights, light pillars). Nothing here moves: the
-- client animates the camp locally (client/CampLife). Everything goes in Workspace.Hub so it
-- can be swapped for a modelled camp later without touching the logic in Hub.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MonsterRig = require(script.Parent:WaitForChild("MonsterRig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rigs = Shared:WaitForChild("Rigs")
local Fx = require(Shared:WaitForChild("Config"):WaitForChild("Fx"))
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))

local HubWorld = {}

export type Built = {
	portals: { [string]: Vector3 }, -- portal id -> middle of its pad
	stations: { [string]: Vector3 }, -- station id -> where its hunter stands
	spawn: SpawnLocation,
}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function vec(p: { number }): Vector3
	return Vector3.new(p[1], p[2], p[3])
end

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A flat disc lying on the ground (a cylinder turned so its round faces point up).
local function disc(
	parent: Instance,
	name: string,
	diameter: number,
	height: number,
	at: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = block(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Something only there to carry effects: invisible, never in the way.
local function ghost(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function sequence(points: { { number } }): NumberSequence
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function range(r: { number }): NumberRange
	return NumberRange.new(r[1], r[2] or r[1])
end

-- A particle emitter from a Config/Fx recipe. color is used when the recipe has none.
local function emitter(parent: Instance, recipeName: string, color: Color3?): ParticleEmitter
	local r = Fx.recipes[recipeName]
	local e = Instance.new("ParticleEmitter")
	e.Name = recipeName
	e.Texture = r.texture
	e.Color = ColorSequence.new(if r.color then rgb(r.color) else color or Color3.new(1, 1, 1))
	e.Rate = r.rate
	e.Enabled = r.rate > 0
	e.Lifetime = range(r.lifetime)
	e.Speed = range(r.speed)
	e.Size = sequence(r.size)
	e.Transparency = sequence(r.transparency)
	if r.spread then
		e.SpreadAngle = Vector2.new(r.spread[1], r.spread[2])
	end
	if r.acceleration then
		e.Acceleration = vec(r.acceleration)
	end
	e.Drag = r.drag or 0
	if r.rotSpeed then
		e.RotSpeed = range(r.rotSpeed)
		e.Rotation = NumberRange.new(0, 360)
	end
	e.Brightness = r.brightness or 1
	e.LightEmission = r.lightEmission or 0
	e.LightInfluence = 0
	e.ZOffset = r.zOffset or 0
	if r.squash then
		e.Squash = sequence(r.squash)
	end
	if r.velocityParallel then
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
	end
	if r.shape then
		e.Shape = (Enum.ParticleEmitterShape :: any)[r.shape]
	end
	if r.shapeStyle then
		e.ShapeStyle = (Enum.ParticleEmitterShapeStyle :: any)[r.shapeStyle]
	end
	if r.shapeInOut then
		e.ShapeInOut = (Enum.ParticleEmitterShapeInOut :: any)[r.shapeInOut]
	end
	if r.direction then
		e.EmissionDirection = (Enum.NormalId :: any)[r.direction]
	end
	e.LockedToPart = r.lockedToPart == true
	if r.burst then
		-- The client fires these (client/CampLife), scaled to the player's graphics quality.
		e:SetAttribute("Burst", r.burst)
	end
	e.Parent = parent
	return e
end

-- A point light from Config/Fx. Flicker ones waver on each player's screen.
local function light(parent: Instance, kind: string, color: Color3?, flicker: boolean?): PointLight
	local spec = Fx.lights[kind]
	local l = Instance.new("PointLight")
	l.Range = spec.range
	l.Brightness = spec.brightness
	l.Color = if spec.color then rgb(spec.color) else color or Color3.new(1, 1, 1)
	l.Shadows = false
	if flicker then
		l:SetAttribute("Flicker", true)
	end
	l.Parent = parent
	return l
end

local function attachmentAt(part: BasePart, name: string, worldPosition: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = part
	a.WorldPosition = worldPosition
	return a
end

-- A floating sign: the name in big outlined letters in its color, a small white line under.
local function sign(
	adornee: BasePart,
	title: string,
	subtitle: string,
	color: Color3,
	height: number
)
	local board = Instance.new("BillboardGui")
	board.Name = "Sign"
	board.Size = UDim2.fromOffset(280, 70)
	board.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	board.MaxDistance = 180
	board.LightInfluence = 0
	board.Adornee = adornee
	local function label(
		name: string,
		text: string,
		y: number,
		h: number,
		font: Enum.Font,
		tint: Color3,
		ink: number
	)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, h)
		l.BackgroundTransparency = 1
		l.Font = font
		l.TextScaled = true
		l.Text = text
		l.TextColor3 = tint
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(20, 21, 28)
		stroke.Thickness = ink
		stroke.Parent = l
		l.Parent = board
	end
	label("Title", string.upper(title), 0, 0.6, Enum.Font.FredokaOne, color, 3)
	label("Subtitle", subtitle, 0.62, 0.38, Enum.Font.GothamBold, Color3.fromRGB(240, 242, 246), 2)
	board.Parent = adornee
end

-- A station's hunter, built from its body plan in Shared/Rigs (the imported mesh in
-- ServerStorage.Assets.<rig> when there is one, plain parts otherwise). Stands on `at` facing
-- `facing`. The Root is anchored; client/CampLife animates the joints on each screen. The rig's
-- named points become attachments for effects. Returns the model, its Root and how tall it is.
local function npc(
	parent: Instance,
	rigName: string,
	at: Vector3,
	facing: Vector3
): (Model, BasePart, number)
	local rig = require(Rigs:WaitForChild(rigName)) :: any
	local model = MonsterRig.build(rig, rigName)
	model.Name = "Hunter"
	model:SetAttribute("Rig", rigName)
	-- Streams in whole, so the client never animates half a hunter.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local root = model.PrimaryPart :: BasePart
	root.Anchored = true
	-- Still in rig space here (feet on y = 0), so points go straight in.
	for pointName, point in rig.points or {} do
		local part = model:FindFirstChild(point.segment)
		if part and part:IsA("BasePart") then
			local attachment = Instance.new("Attachment")
			attachment.Name = pointName
			attachment.Parent = part
			attachment.WorldPosition = vec(point.pos)
		end
	end
	local top = 0
	for _, list in { rig.segments, rig.details } do
		for _, piece in list do
			top = math.max(top, piece.pos[2] + piece.size[2] / 2)
		end
	end
	-- A dark outline around the whole figure, so they read like characters, not scenery.
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(20, 21, 28)
	outline.OutlineTransparency = 0.25
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	model:PivotTo(
		CFrame.lookAt(at, Vector3.new(facing.X, at.Y, facing.Z)) * CFrame.new(0, rig.hipHeight, 0)
	)
	model.Parent = parent
	return model, root, top - rig.hipHeight
end

-- The camp floats: a rock island under the plaza, so the edge reads as a cliff into the sky.
local function buildIsland(folder: Folder, origin: Vector3, radius: number)
	local rock = Color3.fromRGB(92, 78, 70)
	local tiers = { { 2.0, 8 }, { 1.7, 10 }, { 1.3, 12 }, { 0.85, 14 }, { 0.4, 16 } }
	local depth = 4
	for i, tier in tiers do
		local height = tier[2]
		depth += height
		local part = disc(
			folder,
			"Island",
			radius * tier[1],
			height,
			origin - Vector3.new(0, depth - height / 2, 0),
			rock:Lerp(Color3.fromRGB(58, 48, 46), i / #tiers),
			Enum.Material.Rock
		)
		part.CanQuery = false
	end
	-- Loose rocks hanging under the rim.
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2 + 0.3
		local at = origin
			+ Vector3.new(
				math.cos(a) * radius * 0.82,
				-10 - (i % 3) * 5,
				math.sin(a) * radius * 0.82
			)
		local part = block(
			folder,
			"HangingRock",
			Vector3.new(7 + i % 4, 10 + (i % 3) * 3, 7),
			CFrame.new(at) * CFrame.Angles(0.2 * (i % 2), a, 0.15),
			Color3.fromRGB(80, 68, 62),
			Enum.Material.Rock
		)
		part.CanQuery = false
	end
end

local function buildPlaza(folder: Folder, origin: Vector3, radius: number)
	local slate = Color3.fromRGB(58, 66, 74)
	disc(folder, "Plaza", radius * 2, 4, origin - Vector3.new(0, 2, 0), slate, Enum.Material.Slate)
	disc(
		folder,
		"InnerRing",
		radius * 1.3,
		0.4,
		origin + Vector3.new(0, 0.2, 0),
		Color3.fromRGB(84, 90, 96),
		Enum.Material.Cobblestone
	)
	-- Low stone rim to look at, and an invisible wall so nobody walks off the edge.
	local pieces = 40
	for i = 1, pieces do
		local a = (i / pieces) * math.pi * 2
		local at = origin + Vector3.new(math.cos(a) * (radius - 1), 1.5, math.sin(a) * (radius - 1))
		local width = 2 * math.pi * radius / pieces + 0.5
		local cf = CFrame.lookAt(at, origin + Vector3.new(0, 1.5, 0))
		block(
			folder,
			"Rim",
			Vector3.new(width, 3, 2),
			cf,
			Color3.fromRGB(92, 84, 72),
			Enum.Material.Rock
		)
		local wall = block(
			folder,
			"EdgeWall",
			Vector3.new(width, 30, 1),
			cf * CFrame.new(0, 13.5, 0),
			slate,
			Enum.Material.SmoothPlastic
		)
		wall.Transparency = 1
	end
	-- Fireflies drifting over the whole plaza.
	local air = block(
		folder,
		"Fireflies",
		Vector3.new(radius * 1.7, 8, radius * 1.7),
		CFrame.new(origin + Vector3.new(0, 6, 0)),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	ghost(air)
	emitter(air, "fireflies")
end

-- A stone brazier with a fire, embers and a warm flickering light.
local function buildBrazier(folder: Folder, at: Vector3)
	local model = Instance.new("Model")
	model.Name = "Brazier"
	block(
		model,
		"Pillar",
		Vector3.new(1.6, 4, 1.6),
		CFrame.new(at + Vector3.new(0, 2, 0)),
		Color3.fromRGB(96, 86, 76),
		Enum.Material.Rock
	)
	disc(
		model,
		"Bowl",
		3.4,
		0.9,
		at + Vector3.new(0, 4.4, 0),
		Color3.fromRGB(52, 46, 44),
		Enum.Material.Metal
	)
	local coals = disc(
		model,
		"Coals",
		2.6,
		0.3,
		at + Vector3.new(0, 4.9, 0),
		Color3.fromRGB(255, 110, 40),
		Enum.Material.Neon
	)
	local fire = attachmentAt(coals, "Fire", at + Vector3.new(0, 5.2, 0))
	emitter(fire, "flame")
	emitter(fire, "embers")
	light(fire, "brazier", nil, true)
	model.Parent = folder
end

-- Lanterns strung on a sagging rope between two poles; the middle one lights up. a and b are
-- the tops of the poles, which stand on the plaza at height `ground`.
local function buildLanternString(
	folder: Folder,
	a: Vector3,
	b: Vector3,
	ground: number,
	colors: { Color3 }
)
	local model = Instance.new("Model")
	model.Name = "LanternString"
	local length = (b - a).Magnitude
	local count = math.max(4, math.floor(length / 5 + 0.5))
	local sag = length * 0.08
	local function along(t: number): Vector3
		return a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
	end
	for _, top in { a, b } do
		local h = top.Y - ground
		block(
			model,
			"Pole",
			Vector3.new(0.6, h + 0.6, 0.6),
			CFrame.new(top.X, ground + h / 2 + 0.3, top.Z),
			Color3.fromRGB(90, 64, 42),
			Enum.Material.Wood
		)
	end
	for i = 0, count - 1 do
		local p0, p1 = along(i / count), along((i + 1) / count)
		local rope = block(
			model,
			"Rope",
			Vector3.new(0.12, 0.12, (p1 - p0).Magnitude),
			CFrame.lookAt((p0 + p1) / 2, p1),
			Color3.fromRGB(60, 44, 34),
			Enum.Material.Fabric
		)
		rope.CanCollide = false
		rope.CanQuery = false
	end
	for i = 1, count - 1 do
		local p = along(i / count) - Vector3.new(0, 0.7, 0)
		local lantern = block(
			model,
			"Lantern",
			Vector3.new(0.7, 0.9, 0.7),
			CFrame.new(p),
			colors[(i - 1) % #colors + 1],
			Enum.Material.Neon
		)
		lantern.CanCollide = false
		lantern.CanQuery = false
		if i == math.ceil(count / 2) then
			light(lantern, "lantern", nil, true)
		end
	end
	model.Parent = folder
end

-- Rift crystals hovering just past the rim; they bob and turn on each screen.
local function buildCrystals(folder: Folder, origin: Vector3, radius: number)
	local holder = Instance.new("Folder")
	holder.Name = "Crystals"
	local colors = {
		Color3.fromRGB(224, 91, 208),
		Color3.fromRGB(111, 211, 255),
		Color3.fromRGB(255, 194, 74),
	}
	local angles = { 200, 230, 262, 298, 330, 355 }
	for i, deg in angles do
		local a = math.rad(deg)
		local at = origin
			+ Vector3.new(math.cos(a) * (radius + 8), 8 + (i % 3) * 3, -math.sin(a) * (radius + 8))
		local crystal = block(
			holder,
			"Crystal",
			Vector3.new(2, 5.5, 2),
			CFrame.new(at) * CFrame.Angles(0, math.rad(45), math.rad(12)),
			colors[(i - 1) % #colors + 1],
			Enum.Material.Neon
		)
		crystal.CanCollide = false
		crystal.CanQuery = false
	end
	holder.Parent = folder
end

local function buildPortal(
	folder: Folder,
	origin: Vector3,
	config: any,
	arcRadius: number,
	open: boolean
): Vector3
	local a = math.rad(config.angle)
	local scale = config.size or 1
	local outward = Vector3.new(math.cos(a), 0, -math.sin(a))
	local padAt = origin + outward * arcRadius
	local color = rgb(config.color)
	local model = Instance.new("Model")
	model.Name = config.id
	-- Streams in whole, so the client never spins half a ring.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local pad = disc(
		model,
		"Pad",
		14 * scale,
		0.6,
		padAt + Vector3.new(0, 0.3, 0),
		color,
		Enum.Material.Slate
	)
	pad.Color = color:Lerp(Color3.new(0, 0, 0), if open then 0.45 else 0.7)
	if open then
		-- A glowing ring of runes on the pad.
		local rune = disc(
			model,
			"PadGlow",
			11 * scale,
			0.65,
			padAt + Vector3.new(0, 0.3, 0),
			color,
			Enum.Material.Neon
		)
		rune.Transparency = 0.55
		rune.CanQuery = false
	end

	-- An upright ring of stones behind the pad, facing the plaza's middle. The stones hang off
	-- an invisible hub so the client can turn the whole ring slowly.
	local ringAt = padAt + outward * 5 * scale + Vector3.new(0, 8 * scale, 0)
	local facing = CFrame.lookAt(ringAt, Vector3.new(origin.X, ringAt.Y, origin.Z))
	local ringRadius = 7 * scale
	local hub =
		block(model, "Ring", Vector3.new(1, 1, 1), facing, color, Enum.Material.SmoothPlastic)
	ghost(hub)
	local stones = 18
	for i = 1, stones do
		local t = (i / stones) * math.pi * 2
		local cf = facing
			* CFrame.new(math.cos(t) * ringRadius, math.sin(t) * ringRadius, 0)
			* CFrame.Angles(0, 0, t)
		local stone = block(
			model,
			"Frame",
			Vector3.new(1.6, 2.8 * scale, 1.6),
			cf,
			Color3.fromRGB(70, 64, 58),
			Enum.Material.Rock
		)
		if i % 3 == 0 then
			stone.Color = if open then color else color:Lerp(Color3.fromRGB(40, 42, 48), 0.7)
			stone.Material = if open then Enum.Material.Neon else Enum.Material.Glass
		end
		if open then
			stone.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hub
			weld.Part1 = stone
			weld.Parent = stone
		end
	end
	local surface = block(
		model,
		"Surface",
		Vector3.new(0.4, ringRadius * 2 - 1, ringRadius * 2 - 1),
		facing * CFrame.Angles(0, math.rad(90), 0),
		if open then color else Color3.fromRGB(28, 32, 38),
		if open then Enum.Material.Neon else Enum.Material.Slate
	)
	surface.Shape = Enum.PartType.Cylinder
	surface.Transparency = if open then 0.45 else 0
	surface.CanCollide = false

	local monster = config.monsterId and Monsters[config.monsterId]
	local line = if open and monster
		then `Rift Rank {config.minRank} · {monster.displayName}`
		elseif config.monsterId then `Rift Rank {config.minRank}`
		else "Coming soon"
	sign(
		hub,
		config.displayName,
		line,
		if open then color else Color3.fromRGB(170, 176, 190),
		ringRadius + 3.5
	)

	if open then
		-- Sparks swirl from the rim into the middle (a flat disc facing the plaza).
		local vortex = block(
			model,
			"Vortex",
			Vector3.new(ringRadius * 2 - 2, 0.2, ringRadius * 2 - 2),
			facing * CFrame.Angles(math.rad(90), 0, 0),
			color,
			Enum.Material.SmoothPlastic
		)
		ghost(vortex)
		emitter(vortex, "portalVortex", color:Lerp(Color3.new(1, 1, 1), 0.25))
		emitter(pad, "portalMotes", color:Lerp(Color3.new(1, 1, 1), 0.35))
		light(surface, "portal", color)
		-- A soft column of light straight up, so the open portals stand out across the camp.
		local spec = Fx.portalPillar
		local base = attachmentAt(pad, "PillarBase", padAt + Vector3.new(0, 0.6, 0))
		local top = attachmentAt(pad, "PillarTop", padAt + Vector3.new(0, spec.height, 0))
		local beam = Instance.new("Beam")
		beam.Name = "Pillar"
		beam.Attachment0 = base
		beam.Attachment1 = top
		beam.Width0 = spec.width0 * scale
		beam.Width1 = spec.width1 * scale
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Brightness = 2
		beam.Segments = 12
		beam.Color = ColorSequence.new(color)
		beam.Transparency = sequence(spec.transparency)
		beam.Parent = pad
	end
	model:SetAttribute("Open", open)
	model.PrimaryPart = pad
	model.Parent = folder
	return padAt
end

-- The stall around each hunter: an awning on two posts, then props for the station's job.
local function buildProps(model: Model, look: CFrame, config: any, color: Color3)
	local function at(x: number, y: number, z: number): CFrame
		return look * CFrame.new(x, y, z)
	end
	local wood = Color3.fromRGB(110, 78, 50)
	local kind = config.kind
	if kind ~= "forge" and kind ~= "board" then
		block(
			model,
			"Counter",
			Vector3.new(10, 3.4, 2.4),
			at(0, 1.7, -3),
			wood,
			Enum.Material.WoodPlanks
		)
	end
	block(
		model,
		"Awning",
		Vector3.new(12, 0.6, 7),
		at(0, 9, -1) * CFrame.Angles(math.rad(-12), 0, 0),
		color,
		Enum.Material.Fabric
	)
	for _, x in { -5.5, 5.5 } do
		block(
			model,
			"Post",
			Vector3.new(0.8, 9, 0.8),
			at(x, 4.5, 2),
			Color3.fromRGB(90, 64, 42),
			Enum.Material.Wood
		)
	end

	if kind == "forge" then
		-- Anvil in front of Brannoc (sparks when the hammer lands) and the forge behind him.
		local metal = Color3.fromRGB(58, 60, 66)
		block(
			model,
			"AnvilFoot",
			Vector3.new(1.3, 1.5, 1.1),
			at(2.4, 0.75, -2.3),
			metal,
			Enum.Material.Metal
		)
		local top = block(
			model,
			"AnvilTop",
			Vector3.new(2.4, 0.7, 1.1),
			at(2.4, 1.85, -2.3),
			metal,
			Enum.Material.Metal
		)
		local sparks = attachmentAt(top, "AnvilSparks", at(2.4, 2.3, -2.3).Position)
		emitter(sparks, "anvil")
		local flash = light(sparks, "forge", nil)
		flash.Brightness = 0.4
		flash.Range = 10
		flash:SetAttribute("Flash", true)
		local brick = Color3.fromRGB(122, 64, 50)
		block(
			model,
			"Forge",
			Vector3.new(3.8, 3.4, 3.4),
			at(-3.6, 1.7, 1.2),
			brick,
			Enum.Material.Brick
		)
		block(
			model,
			"Chimney",
			Vector3.new(1.8, 7, 1.8),
			at(-3.6, 6.9, 1.6),
			brick,
			Enum.Material.Brick
		)
		local mouth = block(
			model,
			"ForgeMouth",
			Vector3.new(2.2, 1.2, 0.3),
			at(-3.6, 1.6, -0.45),
			Color3.fromRGB(255, 120, 40),
			Enum.Material.Neon
		)
		local fire = attachmentAt(mouth, "Fire", at(-3.6, 1.8, -0.8).Position)
		emitter(fire, "embers")
		light(fire, "forge", nil, true)
		local chimneyTop = attachmentAt(mouth, "Smoke", at(-3.6, 10.6, 1.6).Position)
		emitter(chimneyTop, "smoke")
	elseif kind == "upgrade" then
		-- A ring of glowing runes turning over the bench, with dust rising off it.
		local runes = block(
			model,
			"Runes",
			Vector3.new(3.2, 0.4, 3.2),
			at(0, 5, -3),
			color,
			Enum.Material.SmoothPlastic
		)
		ghost(runes)
		for i = 1, 8 do
			local t = i / 8 * math.pi * 2
			local rune = block(
				model,
				"Rune",
				Vector3.new(0.5, 0.5, 0.12),
				at(math.cos(t) * 1.5, 5, -3 + math.sin(t) * 1.5) * CFrame.Angles(0, -t, 0),
				color,
				Enum.Material.Neon
			)
			rune.Anchored = false
			rune.CanCollide = false
			rune.CanQuery = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = runes
			weld.Part1 = rune
			weld.Parent = rune
		end
		emitter(runes, "magicDust", color)
		block(
			model,
			"Stone",
			Vector3.new(0.9, 0.9, 0.9),
			at(0, 3.85, -3) * CFrame.Angles(0, math.rad(45), math.rad(35)),
			color,
			Enum.Material.Neon
		)
		light(runes, "lantern", color)
	elseif kind == "board" then
		-- The Hunting Board itself, with contracts pinned to it and a trophy skull on top.
		local board = at(-3.4, 0, -1.6)
		for _, x in { -2.8, 2.8 } do
			block(
				model,
				"BoardPost",
				Vector3.new(0.5, 7, 0.5),
				board * CFrame.new(x, 3.5, 0),
				Color3.fromRGB(90, 64, 42),
				Enum.Material.Wood
			)
		end
		block(
			model,
			"Board",
			Vector3.new(6, 4, 0.4),
			board * CFrame.new(0, 4.4, 0),
			wood,
			Enum.Material.WoodPlanks
		)
		block(
			model,
			"BoardTrim",
			Vector3.new(6.2, 0.18, 0.12),
			board * CFrame.new(0, 6.5, -0.25),
			color,
			Enum.Material.Neon
		)
		local notes = {
			{ -1.8, 5.1, 1.1, 1.3 },
			{ -0.4, 4.6, 1.2, 1.5 },
			{ 1.1, 5.2, 1.0, 1.2 },
			{ 2.1, 3.9, 0.9, 1.1 },
			{ -1.2, 3.3, 1.1, 1.0 },
		}
		for _, n in notes do
			block(
				model,
				"Contract",
				Vector3.new(n[3], n[4], 0.06),
				board
					* CFrame.new(n[1], n[2], -0.24)
					* CFrame.Angles(0, 0, math.rad((n[1] * 7) % 9 - 4)),
				Color3.fromRGB(240, 228, 196),
				Enum.Material.SmoothPlastic
			)
			local pin = block(
				model,
				"Pin",
				Vector3.new(0.22, 0.22, 0.22),
				board * CFrame.new(n[1], n[2] + n[4] / 2 - 0.15, -0.3),
				Color3.fromRGB(214, 48, 58),
				Enum.Material.SmoothPlastic
			)
			pin.Shape = Enum.PartType.Ball
		end
		local skull = block(
			model,
			"Trophy",
			Vector3.new(1.6, 1.3, 1.8),
			board * CFrame.new(0, 7.1, 0),
			Color3.fromRGB(236, 228, 210),
			Enum.Material.SmoothPlastic
		)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = skull
		for _, side in { -1, 1 } do
			local horn = Instance.new("WedgePart")
			horn.Name = "Horn"
			horn.Anchored = true
			horn.Size = Vector3.new(0.35, 1.4, 0.8)
			horn.CFrame = board
				* CFrame.new(0.75 * side, 7.8, 0.1)
				* CFrame.Angles(0, 0, math.rad(-25 * side))
			horn.Color = Color3.fromRGB(232, 142, 38)
			horn.Material = Enum.Material.SmoothPlastic
			horn.Parent = model
		end
	elseif kind == "shop" then
		-- Crates and a barrel, and a lantern hanging from the awning.
		block(
			model,
			"Crate",
			Vector3.new(2.2, 2.2, 2.2),
			at(3.8, 1.1, 0.8) * CFrame.Angles(0, math.rad(12), 0),
			Color3.fromRGB(150, 108, 64),
			Enum.Material.WoodPlanks
		)
		block(
			model,
			"Crate",
			Vector3.new(1.7, 1.7, 1.7),
			at(3.6, 3.05, 0.9) * CFrame.Angles(0, math.rad(-8), 0),
			Color3.fromRGB(128, 90, 54),
			Enum.Material.WoodPlanks
		)
		local barrel = block(
			model,
			"Barrel",
			Vector3.new(2.6, 2.2, 2.2),
			at(-3.8, 1.3, 1) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(118, 78, 46),
			Enum.Material.Wood
		)
		barrel.Shape = Enum.PartType.Cylinder
		for _, x in { -2.5, 0, 2.5 } do
			local sack = block(
				model,
				"Sack",
				Vector3.new(1.3, 1, 1.1),
				at(x, 3.9, -3.1),
				Color3.fromRGB(196, 170, 120),
				Enum.Material.Fabric
			)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = sack
		end
		block(
			model,
			"Chain",
			Vector3.new(0.1, 1.6, 0.1),
			at(4.6, 7.4, -3.6),
			Color3.fromRGB(60, 60, 64),
			Enum.Material.Metal
		)
		local lantern = block(
			model,
			"Lantern",
			Vector3.new(0.8, 1, 0.8),
			at(4.6, 6.1, -3.6),
			Color3.fromRGB(255, 205, 130),
			Enum.Material.Neon
		)
		lantern.CanCollide = false
		light(lantern, "lantern", nil, true)
	end
end

local function buildNest(model: Model, at: Vector3, color: Color3)
	-- The Nest Spire: a crystal column with the featured egg in its shadow and shards circling.
	block(
		model,
		"Spire",
		Vector3.new(5, 26, 5),
		CFrame.new(at + Vector3.new(0, 13, -6)) * CFrame.Angles(0, math.rad(45), 0),
		color:Lerp(Color3.new(0, 0, 0), 0.4),
		Enum.Material.Glass
	)
	block(
		model,
		"SpireTip",
		Vector3.new(3, 6, 3),
		CFrame.new(at + Vector3.new(0, 29, -6)) * CFrame.Angles(0, math.rad(45), 0),
		color,
		Enum.Material.Neon
	)
	local shards = block(
		model,
		"Shards",
		Vector3.new(1, 1, 1),
		CFrame.new(at + Vector3.new(0, 18, -6)),
		color,
		Enum.Material.SmoothPlastic
	)
	ghost(shards)
	for i = 1, 3 do
		local t = i / 3 * math.pi * 2
		local shard = block(
			model,
			"Shard",
			Vector3.new(1, 2.6, 1),
			CFrame.new(at + Vector3.new(math.cos(t) * 5, 18 + i, -6 + math.sin(t) * 5))
				* CFrame.Angles(0, t, math.rad(20)),
			Color3.fromRGB(111, 211, 255),
			Enum.Material.Neon
		)
		shard.Anchored = false
		shard.CanCollide = false
		shard.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = shards
		weld.Part1 = shard
		weld.Parent = shard
	end
	-- The egg is a dark silhouette: you know which monster, not what the egg looks like. A
	-- glowing shell around it pulses on each screen.
	local egg = block(
		model,
		"Egg",
		Vector3.new(4, 5.5, 4),
		CFrame.new(at + Vector3.new(0, 3.5, -2)),
		Color3.fromRGB(8, 10, 14),
		Enum.Material.SmoothPlastic
	)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	local halo =
		block(model, "EggGlow", Vector3.new(4.8, 6.4, 4.8), egg.CFrame, color, Enum.Material.Neon)
	halo.Transparency = 0.8
	halo.CanCollide = false
	halo.CanQuery = false
	local haloMesh = mesh:Clone()
	haloMesh.Parent = halo
	local dust = block(
		model,
		"EggDust",
		Vector3.new(6, 7, 6),
		egg.CFrame,
		color,
		Enum.Material.SmoothPlastic
	)
	ghost(dust)
	emitter(dust, "magicDust", color:Lerp(Color3.new(1, 1, 1), 0.3))
	light(egg, "egg", color)
	disc(
		model,
		"Nest",
		10,
		1.2,
		at + Vector3.new(0, 0.6, -2),
		Color3.fromRGB(96, 78, 56),
		Enum.Material.Grass
	)
end

-- Effects on the hunters themselves, at the points their rigs name.
local function npcFx(hunter: Model, color: Color3)
	for _, a in hunter:GetDescendants() do
		if a:IsA("Attachment") then
			if a.Name == "Stone" or a.Name == "Wisp" then
				emitter(a, "trail", color:Lerp(Color3.new(1, 1, 1), 0.3))
			elseif a.Name == "Coin" then
				emitter(a, "glint")
			elseif a.Name == "Lantern" then
				light(a, "lantern", nil, true)
			end
		end
	end
end

local function buildStation(folder: Folder, origin: Vector3, config: any, reach: number): Vector3
	local at = origin + vec(config.position)
	local color = rgb(config.color)
	local model = Instance.new("Model")
	model.Name = config.id
	local toMiddle = (Vector3.new(origin.X, at.Y, origin.Z) - at)
	local dir = if toMiddle.Magnitude > 0.1 then toMiddle.Unit else Vector3.new(0, 0, 1)
	local look = CFrame.lookAt(at, at + dir)
	if config.kind == "nest" then
		buildNest(model, at, color)
	else
		buildProps(model, look, config, color)
	end
	local standAt = if config.kind == "nest" then at + Vector3.new(4, 0, 2) else at
	local hunter, body, height = npc(model, config.rig, standAt, origin)
	hunter:SetAttribute("Station", config.id)
	npcFx(hunter, color)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Talk"
	prompt.ObjectText = config.npc
	prompt.ActionText = config.title
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = reach - 4
	prompt:SetAttribute("Station", config.id)
	prompt:SetAttribute("Kind", config.kind)
	prompt.Parent = body
	sign(body, config.title, config.npc, color, height + 2.2)
	model.Parent = folder
	return standAt
end

function HubWorld.build(Hub: any, openPortals: { [string]: boolean }): Built
	local old = Workspace:FindFirstChild("Hub")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Hub"
	local origin = vec(Hub.origin)
	buildIsland(folder, origin, Hub.plazaRadius)
	buildPlaza(folder, origin, Hub.plazaRadius)
	buildCrystals(folder, origin, Hub.plazaRadius)
	for _, p in Hub.braziers do
		buildBrazier(folder, origin + vec(p))
	end
	local warm = {
		Color3.fromRGB(255, 194, 74),
		Color3.fromRGB(255, 138, 61),
		Color3.fromRGB(255, 226, 150),
	}
	for _, pair in Hub.lanternStrings do
		buildLanternString(folder, origin + vec(pair[1]), origin + vec(pair[2]), origin.Y, warm)
	end

	local portalFolder = Instance.new("Folder")
	portalFolder.Name = "Portals"
	portalFolder.Parent = folder
	local portals = {}
	for _, portal in Hub.portals do
		portals[portal.id] = buildPortal(
			portalFolder,
			origin,
			portal,
			Hub.portalArcRadius,
			openPortals[portal.id] == true
		)
	end

	local stationFolder = Instance.new("Folder")
	stationFolder.Name = "Stations"
	stationFolder.Parent = folder
	local stations = {}
	for _, station in Hub.stations do
		stations[station.id] = buildStation(stationFolder, origin, station, Hub.stationReach)
	end

	local spawnAt = origin + vec(Hub.spawn) + Vector3.new(0, 0.5, 0)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CampSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	-- Spawn facing north, so the portal arc fills the first view.
	spawn.CFrame = CFrame.lookAt(spawnAt, spawnAt + Vector3.new(0, 0, -1))
	spawn.Color = Color3.fromRGB(154, 167, 180)
	spawn.Material = Enum.Material.Slate
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	folder.Parent = Workspace
	return { portals = portals, stations = stations, spawn = spawn }
end

return HubWorld
