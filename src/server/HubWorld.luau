--!strict
-- Builds Rift Camp from Config/Hub out of plain parts: the plaza, the portal arc, the
-- stations with their hunters, the Nest Spire and the spawn. Everything goes in Workspace.Hub
-- so it can be swapped for a modelled camp later without touching the logic in Hub.luau.

local Workspace = game:GetService("Workspace")

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

-- A floating sign with a big line and a small line.
local function sign(
	adornee: BasePart,
	title: string,
	subtitle: string,
	color: Color3,
	height: number
)
	local board = Instance.new("BillboardGui")
	board.Name = "Sign"
	board.Size = UDim2.fromOffset(260, 64)
	board.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	board.MaxDistance = 180
	board.LightInfluence = 0
	board.Adornee = adornee
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Oswald
	titleLabel.TextScaled = true
	titleLabel.Text = string.upper(title)
	titleLabel.TextColor3 = color
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.Parent = board
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Position = UDim2.fromScale(0, 0.6)
	subLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextScaled = true
	subLabel.Text = subtitle
	subLabel.TextColor3 = Color3.fromRGB(238, 242, 245)
	subLabel.TextStrokeTransparency = 0.3
	subLabel.Parent = board
	board.Parent = adornee
end

-- A simple stand-in hunter: legs, body, head and a coloured sash. Faces `facing`.
local function npc(
	parent: Instance,
	name: string,
	at: Vector3,
	facing: Vector3,
	color: Color3
): Part
	local model = Instance.new("Model")
	model.Name = name
	local look = CFrame.lookAt(at, Vector3.new(facing.X, at.Y, facing.Z))
	local skin = Color3.fromRGB(198, 150, 112)
	local cloth = Color3.fromRGB(70, 62, 56)
	block(
		model,
		"Legs",
		Vector3.new(1.8, 2.4, 1),
		look * CFrame.new(0, 1.2, 0),
		cloth,
		Enum.Material.Fabric
	)
	local body = block(
		model,
		"Body",
		Vector3.new(2.2, 2.4, 1.2),
		look * CFrame.new(0, 3.6, 0),
		Color3.fromRGB(96, 84, 72),
		Enum.Material.Fabric
	)
	block(
		model,
		"Sash",
		Vector3.new(2.3, 0.5, 1.3),
		look * CFrame.new(0, 3.4, 0),
		color,
		Enum.Material.Fabric
	)
	block(
		model,
		"Head",
		Vector3.new(1.3, 1.3, 1.3),
		look * CFrame.new(0, 5.5, 0),
		skin,
		Enum.Material.SmoothPlastic
	)
	model.PrimaryPart = body
	model.Parent = parent
	return body
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

	local pad = disc(
		model,
		"Pad",
		14 * scale,
		0.6,
		padAt + Vector3.new(0, 0.3, 0),
		color,
		Enum.Material.Slate
	)
	pad.Color = color:Lerp(Color3.new(0, 0, 0), 0.55)

	-- An upright ring of stones behind the pad, facing the plaza's middle.
	local ringAt = padAt + outward * 5 * scale + Vector3.new(0, 8 * scale, 0)
	local facing = CFrame.lookAt(ringAt, Vector3.new(origin.X, ringAt.Y, origin.Z))
	local ringRadius = 7 * scale
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
			stone.Color = color
			stone.Material = if open then Enum.Material.Neon else Enum.Material.Glass
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
	surface.Transparency = if open then 0.35 else 0
	surface.CanCollide = false
	if open then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 18
		light.Brightness = 2
		light.Parent = surface
	end
	model:SetAttribute("Open", open)
	model.PrimaryPart = pad
	model.Parent = folder
	return padAt
end

local function buildStation(folder: Folder, origin: Vector3, config: any, reach: number): Vector3
	local at = origin + vec(config.position)
	local color = rgb(config.color)
	local model = Instance.new("Model")
	model.Name = config.id
	-- The stall: a counter between the hunter and the plaza's middle, and an awning.
	local toMiddle = (Vector3.new(origin.X, at.Y, origin.Z) - at)
	local dir = if toMiddle.Magnitude > 0.1 then toMiddle.Unit else Vector3.new(0, 0, 1)
	local look = CFrame.lookAt(at, at + dir)
	if config.kind ~= "nest" then
		block(
			model,
			"Counter",
			Vector3.new(10, 3.4, 2.4),
			look * CFrame.new(0, 1.7, -3),
			Color3.fromRGB(110, 78, 50),
			Enum.Material.WoodPlanks
		)
		block(
			model,
			"Awning",
			Vector3.new(12, 0.6, 7),
			look * CFrame.new(0, 9, -1) * CFrame.Angles(math.rad(-12), 0, 0),
			color,
			Enum.Material.Fabric
		)
		for _, x in { -5.5, 5.5 } do
			block(
				model,
				"Post",
				Vector3.new(0.8, 9, 0.8),
				look * CFrame.new(x, 4.5, 2),
				Color3.fromRGB(90, 64, 42),
				Enum.Material.Wood
			)
		end
	else
		-- The Nest Spire: a crystal column with the next egg in its shadow.
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
		local egg = block(
			model,
			"Egg",
			Vector3.new(4, 5.5, 4),
			CFrame.new(at + Vector3.new(0, 3.5, -2)),
			Color3.fromRGB(8, 10, 14),
			Enum.Material.SmoothPlastic
		)
		-- Egg shaped: a sphere mesh stretched upward.
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = egg
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
	local standAt = if config.kind == "nest" then at + Vector3.new(4, 0, 2) else at
	local body = npc(model, "Hunter", standAt, origin, color)

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
	sign(body, config.title, config.npc, color, 4)
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
	buildPlaza(folder, origin, Hub.plazaRadius)

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
