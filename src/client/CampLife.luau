--!strict
-- Brings Rift Camp to life on this player's screen. The server builds everything once and
-- never moves it; this module animates it locally, so it costs no network traffic:
-- - the station hunters breathe, turn their heads to you, wave and say a line when you walk
--   up, and do their work (Brannoc hammers the anvil and sparks fly, Pell flips his coin);
--   the quest giver has a bouncing "!";
-- - open portals' rings turn and their middles breathe, the upgrade runes and the spire's
--   shards circle, the rift crystals bob, fires and lanterns flicker and the egg pulses;
-- - the camp gets its own warm dusk light with bloom (Config/Fx camp) while you are in it.
-- Particles follow the player's graphics quality (Roblox no longer scales them), Reduce Motion
-- stops everything spinning and bobbing, and outside camp it all stops.
-- Parts can stream in and out, so everything is picked up as it arrives (DescendantAdded) and
-- dropped once it is gone.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Hub = require(Config:WaitForChild("Hub"))
local Fx = require(Config:WaitForChild("Fx"))
local Rigs = Shared:WaitForChild("Rigs")
local Ui = require(script.Parent:WaitForChild("Ui"))

local CampLife = {}

local player = Players.LocalPlayer

-- How close you have to be for a hunter to notice you, and to greet you.
local LOOK_RANGE = 26
local GREET_RANGE = 16
local GREET_COOLDOWN = 25
-- Hunters further than this from the camera are not animated at all.
local ANIMATE_RANGE = 160
-- Flicker and glow pulses update this many times a second (smooth enough, and cheaper).
local SLOW_HZ = 15
-- Below this graphics quality the hunters lose their outlines (they cost GPU on phones).
local OUTLINE_QUALITY = 0.4

type Npc = {
	model: Model,
	root: BasePart,
	rig: any,
	station: Hub.Station,
	joints: { [string]: Motor6D },
	phase: number,
	yaw: number,
	pitch: number,
	near: boolean,
	greetedAt: number,
	waveStart: number,
	lineIndex: number,
	nextWork: number,
}

-- Something that turns or bobs: its resting CFrame (as the server built it) and how it moves.
type Mover = { base: CFrame, kind: string, phase: number }
-- Something that glows up and down: what it started at.
type Glow = { base: number, kind: string, seed: number }

local npcs: { Npc } = {}
local tracked: { [Model]: boolean } = {}
local movers: { [BasePart]: Mover } = {}
local glows: { [Instance]: Glow } = {}
local emitters: { [ParticleEmitter]: number } = {}
local outlines: { [Highlight]: boolean } = {}

local stationById: { [string]: Hub.Station } = {}
for _, station in Hub.stations do
	stationById[station.id] = station
end

local inCamp = false
-- 0.3 to 1: how much of each particle effect this player's graphics setting gets.
local quality = 1

local function readQuality(): number
	local ok, level = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel
	end)
	local value = if ok then level.Value else 0
	if value == 0 then
		-- Automatic: Roblox picks per device. Phones get a lighter camp.
		return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
			then 0.6
			else 1
	end
	return math.clamp(value / 10, 0.3, 1)
end

-- An emitter's rate for this player: its built rate scaled to quality, and none outside camp.
local function tuneEmitter(emitter: ParticleEmitter, rate: number)
	emitter.Rate = rate * quality
	emitter.Enabled = inCamp and rate > 0
end

local function tuneAll()
	for emitter, rate in emitters do
		if emitter.Parent then
			tuneEmitter(emitter, rate)
		else
			emitters[emitter] = nil
		end
	end
	for outline in outlines do
		if outline.Parent then
			outline.Enabled = quality >= OUTLINE_QUALITY
		else
			outlines[outline] = nil
		end
	end
end

-- Fires every particle emitter under `holder` that is set up for bursts (Burst attribute),
-- scaled to quality, and flashes any light marked Flash.
local function burst(holder: Instance?)
	if not holder then
		return
	end
	for _, item in holder:GetDescendants() do
		if item:IsA("ParticleEmitter") then
			local count = item:GetAttribute("Burst")
			if typeof(count) == "number" then
				item:Emit(math.max(1, math.floor(count * quality + 0.5)))
			end
		elseif item:IsA("PointLight") and item:GetAttribute("Flash") then
			local base = item.Brightness
			item.Brightness = base * 4
			TweenService:Create(item, TweenInfo.new(0.35), { Brightness = base }):Play()
		end
	end
end

local function ease(k: number): number
	return 1 - (1 - k) ^ 3
end

-- The work swing for one cycle: raise, a short hold, a fast strike, then back to rest.
-- Returns the arm's angle in degrees.
local RAISE, HOLD, STRIKE, BACK = 0.45, 0.12, 0.09, 0.5
local function workAngle(work: any, t: number): number
	if t < RAISE then
		return ease(t / RAISE) * work.raise
	elseif t < RAISE + HOLD then
		return work.raise
	elseif t < RAISE + HOLD + STRIKE then
		local k = (t - RAISE - HOLD) / STRIKE
		return work.raise + (work.strike - work.raise) * k * k
	elseif t < RAISE + HOLD + STRIKE + BACK then
		local k = (t - RAISE - HOLD - STRIKE) / BACK
		return work.strike * (1 - ease(k))
	end
	return 0
end

-- A white speech bubble over the hunter's sign that pops in, holds and fades.
local function say(npc: Npc, text: string, height: number)
	local old = npc.root:FindFirstChild("Bubble")
	if old then
		old:Destroy()
	end
	local board = Instance.new("BillboardGui")
	board.Name = "Bubble"
	board.Size = UDim2.fromOffset(300, 90)
	board.StudsOffsetWorldSpace = Vector3.new(0, height + 5, 0)
	board.MaxDistance = 60
	board.LightInfluence = 0
	board.AlwaysOnTop = true
	board.Adornee = npc.root
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = board
	local bubble = Instance.new("TextLabel")
	bubble.AnchorPoint = Vector2.new(0.5, 1)
	bubble.Position = UDim2.fromScale(0.5, 1)
	bubble.Size = UDim2.fromOffset(0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bubble.Font = Ui.fonts.button
	bubble.TextSize = 20
	bubble.TextColor3 = Ui.colors.ink
	bubble.TextWrapped = true
	bubble.Text = text
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(290, 90)
	limit.Parent = bubble
	Ui.padding(bubble, 10)
	Ui.corner(bubble, 14)
	local c = npc.station.color
	Ui.stroke(bubble, Color3.fromRGB(c[1], c[2], c[3]), 3)
	bubble.Parent = board
	board.Parent = npc.root
	Ui.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(4, function()
		if board.Parent then
			Ui.tween(bubble, 0.4, { BackgroundTransparency = 1, TextTransparency = 1 })
			local s = bubble:FindFirstChildOfClass("UIStroke")
			if s then
				Ui.tween(s, 0.4, { Transparency = 1 })
			end
			task.delay(0.45, function()
				board:Destroy()
			end)
		end
	end)
end

-- The quest giver's "!": big gold, outlined, bouncing above the sign.
local function marker(npc: Npc, text: string, height: number): BillboardGui
	local board = Instance.new("BillboardGui")
	board.Name = "Marker"
	board.Size = UDim2.fromOffset(70, 90)
	board.StudsOffsetWorldSpace = Vector3.new(0, height + 4.2, 0)
	board.MaxDistance = 220
	board.LightInfluence = 0
	board.Adornee = npc.root
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.55)
	glow.Size = UDim2.fromOffset(56, 56)
	glow.BackgroundColor3 = Ui.colors.gold
	glow.BackgroundTransparency = 0.6
	Ui.corner(glow, 28)
	glow.Parent = board
	local mark = Instance.new("TextLabel")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.Size = UDim2.fromScale(1, 1)
	mark.Font = Ui.fonts.button
	mark.TextSize = 72
	mark.TextColor3 = Ui.colors.gold
	mark.Text = text
	Ui.ink(mark, 4)
	mark.Parent = board
	local scale = Instance.new("UIScale")
	scale.Parent = board
	board.Parent = npc.root
	return board
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function height(npc: Npc): number
	local sign = npc.root:FindFirstChild("Sign")
	return if sign and sign:IsA("BillboardGui") then sign.StudsOffsetWorldSpace.Y else 6
end

-- Starts animating a station's hunter once its Root has arrived.
local function track(model: Model)
	if tracked[model] then
		return
	end
	tracked[model] = true
	local rigName = model:GetAttribute("Rig")
	local stationId = model:GetAttribute("Station")
	local root = model:WaitForChild("Root", 10)
	local rigModule = typeof(rigName) == "string" and Rigs:FindFirstChild(rigName)
	local station = if typeof(stationId) == "string" then stationById[stationId] else nil
	if not (rigModule and station and root and root:IsA("BasePart")) then
		tracked[model] = nil
		return
	end
	local rig = require(rigModule :: ModuleScript) :: any
	local joints: { [string]: Motor6D } = {}
	local function addJoint(item: Instance)
		if item:IsA("Motor6D") then
			joints[item.Name] = item
		end
	end
	for _, item in model:GetDescendants() do
		addJoint(item)
	end
	model.DescendantAdded:Connect(addJoint)
	local npc: Npc = {
		model = model,
		root = root,
		rig = rig,
		station = station,
		joints = joints,
		phase = math.random() * 10,
		yaw = 0,
		pitch = 0,
		near = false,
		greetedAt = -math.huge,
		waveStart = -math.huge,
		lineIndex = math.random(1, math.max(1, #station.lines)),
		nextWork = os.clock() + math.random() * 2,
	}
	table.insert(npcs, npc)
	if station.marker then
		marker(npc, station.marker, height(npc))
	end
end

local function animate(npc: Npc, now: number, dt: number, me: Vector3?)
	local idle = npc.rig.idle or {}
	local joints = npc.joints
	local t = now + npc.phase
	local breath = math.sin(t * 2 * math.pi / (idle.period or 3))

	-- Notice the player: turn the head (and a little of the body) toward them.
	local targetYaw, targetPitch = 0, 0
	local distance = math.huge
	if me then
		local rel = npc.root.CFrame:PointToObjectSpace(me + Vector3.new(0, 1.5, 0))
		distance = Vector3.new(rel.X, 0, rel.Z).Magnitude
		if distance < LOOK_RANGE then
			local yaw = math.atan2(-rel.X, -rel.Z)
			if math.abs(yaw) < math.rad(110) then
				targetYaw = math.clamp(yaw, -math.rad(70), math.rad(70))
				targetPitch =
					math.clamp(math.atan2(rel.Y - 3, distance), -math.rad(20), math.rad(25))
			end
		end
	end
	local follow = 1 - math.exp(-dt * 5)
	npc.yaw += (targetYaw - npc.yaw) * follow
	npc.pitch += (targetPitch - npc.pitch) * follow

	-- Walking up: wave and say a line, then not again for a while.
	local isNear = distance < GREET_RANGE
	if isNear and not npc.near and now - npc.greetedAt > GREET_COOLDOWN then
		npc.greetedAt = now
		npc.waveStart = now
		if #npc.station.lines > 0 then
			npc.lineIndex = npc.lineIndex % #npc.station.lines + 1
			say(npc, npc.station.lines[npc.lineIndex], height(npc))
		end
	end
	npc.near = isNear

	local spine = joints.Spine
	if spine then
		spine.Transform = CFrame.new(0, (idle.breathe or 0.05) * breath, 0)
			* CFrame.Angles(math.rad(1.2) * breath, npc.yaw * 0.25, 0)
	end
	local neck = joints.Neck
	if neck then
		neck.Transform = CFrame.Angles(npc.pitch, npc.yaw * 0.75, 0)
	end
	local float = joints.Float
	if float and idle.float then
		float.Transform = CFrame.new(0, idle.float * math.sin(t * 1.6), 0)
	end
	local orbit = joints.Orbit
	if orbit and idle.orbit then
		orbit.Transform = CFrame.Angles(0, math.rad(idle.orbit) * t, 0)
	end

	-- The wave beats the work: the waving arm stops working while it waves.
	local waving = now - npc.waveStart < 1.8
	local waveJoint = idle.waveWith and joints[idle.waveWith]
	if waveJoint then
		local side = if idle.waveWith == "ShoulderR" then 1 else -1
		if waving then
			local k = now - npc.waveStart
			local blend = math.min(1, k / 0.25, (1.8 - k) / 0.3)
			local roll = (140 + 20 * math.sin(k * 14)) * blend
			waveJoint.Transform = CFrame.Angles(0, 0, math.rad(roll * side))
		elseif idle.waveWith ~= (idle.work and idle.work.joint) then
			waveJoint.Transform = CFrame.Angles(0, 0, math.rad(2 * breath * side))
		end
	end
	local work = idle.work
	local workJoint = work and joints[work.joint]
	if work and workJoint and not (waving and work.joint == idle.waveWith) then
		local into = now - npc.nextWork
		if into >= 0 then
			local before = into - dt
			local strikeAt = RAISE + HOLD + STRIKE
			if before < strikeAt and into >= strikeAt and work.at then
				burst(npc.model.Parent and npc.model.Parent:FindFirstChild(work.at, true))
			end
			workJoint.Transform = CFrame.Angles(math.rad(workAngle(work, into)), 0, 0)
			if into > RAISE + HOLD + STRIKE + BACK then
				npc.nextWork = now + work.every * (0.8 + math.random() * 0.4)
			end
		else
			workJoint.Transform = CFrame.identity
		end
	end
end

-- Sorts each piece of the camp into what animates it, as it arrives (names from HubWorld).
local function register(item: Instance)
	local parent = item.Parent
	if item:IsA("ParticleEmitter") then
		emitters[item] = item.Rate
		tuneEmitter(item, item.Rate)
	elseif item:IsA("PointLight") then
		if item:GetAttribute("Flicker") then
			glows[item] = { base = item.Brightness, kind = "flicker", seed = math.random() * 100 }
		elseif parent and parent.Name == "Egg" then
			glows[item] = { base = item.Brightness, kind = "eggLight", seed = 0 }
		end
	elseif item:IsA("Highlight") then
		outlines[item] = true
		item.Enabled = quality >= OUTLINE_QUALITY
	elseif item:IsA("Model") and item.Name == "Hunter" then
		task.spawn(track, item)
	elseif item:IsA("BasePart") then
		local name = item.Name
		local openPortal = parent ~= nil and parent:GetAttribute("Open") == true
		if name == "Ring" and openPortal then
			movers[item] = { base = item.CFrame, kind = "portalRing", phase = 0 }
		elseif (name == "Surface" or name == "PadGlow") and openPortal then
			glows[item] = { base = item.Transparency, kind = "breathe", seed = math.random() * 10 }
		elseif name == "Runes" then
			movers[item] = { base = item.CFrame, kind = "runes", phase = 0 }
		elseif name == "Shards" then
			movers[item] = { base = item.CFrame, kind = "spireShards", phase = 0 }
		elseif name == "Crystal" then
			movers[item] = { base = item.CFrame, kind = "crystals", phase = math.random() * 10 }
		elseif name == "EggGlow" then
			glows[item] = { base = item.Transparency, kind = "egg", seed = 0 }
		end
	end
end

local function moverCFrame(m: Mover, t: number): CFrame
	local spin = math.rad((Fx.spin :: any)[m.kind] or 0) * t
	if m.kind == "portalRing" then
		-- The ring faces the plaza along its Z axis, so it turns about Z like a wheel.
		return m.base * CFrame.Angles(0, 0, spin)
	elseif m.kind == "crystals" then
		return m.base
			* CFrame.new(0, 0.6 * math.sin(t * 0.8 + m.phase), 0)
			* CFrame.Angles(0, spin, 0)
	elseif m.kind == "runes" then
		return m.base * CFrame.new(0, 0.15 * math.sin(t * 1.5), 0) * CFrame.Angles(0, spin, 0)
	end
	return m.base * CFrame.Angles(0, spin, 0)
end

-- Flicker, breathing portals and the egg's pulse, all slow and soft: nothing in camp beats
-- faster than about once a second (research/vfx.md).
local function glowValue(g: Glow, t: number): number
	if g.kind == "flicker" then
		return g.base * (0.85 + 0.3 * math.noise(t * 2.5, g.seed))
	elseif g.kind == "breathe" then
		return math.clamp(g.base + 0.1 * math.sin(t * 2.5 + g.seed), 0, 1)
	elseif g.kind == "egg" then
		return math.clamp(g.base - 0.08 * math.sin(t * math.pi), 0, 1)
	end
	-- eggLight: half a beat a second, in step with the egg's shell.
	return g.base * (0.8 + 0.35 * (0.5 + 0.5 * math.sin(t * math.pi)))
end

local function setGlow(item: Instance, value: number)
	if item:IsA("PointLight") then
		item.Brightness = value
	elseif item:IsA("BasePart") then
		item.Transparency = value
	end
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Camp lighting (Config/Fx camp) on this screen only; leaving puts the hunting ground's back.
local saved: { [string]: any }? = nil
local savedAtmosphere: { [string]: any }? = nil
local campEffects: { Instance } = {}

local function setCampLighting(on: boolean)
	local c = Fx.camp
	for _, effect in campEffects do
		effect:Destroy()
	end
	table.clear(campEffects)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not on then
		if saved then
			Ui.tween(Lighting, 0.8, saved, Enum.EasingStyle.Sine)
		end
		if atmosphere and atmosphere.Name == "CampAtmosphere" then
			atmosphere:Destroy()
		elseif atmosphere and savedAtmosphere then
			for key, value in savedAtmosphere do
				(atmosphere :: any)[key] = value
			end
		end
		return
	end
	if not saved then
		saved = {
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			ExposureCompensation = Lighting.ExposureCompensation,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		}
	end
	Ui.tween(Lighting, 0.8, {
		ClockTime = c.clockTime,
		Brightness = c.brightness,
		ExposureCompensation = c.exposure,
		Ambient = rgb(c.ambient),
		OutdoorAmbient = rgb(c.outdoorAmbient),
	}, Enum.EasingStyle.Sine)
	-- Atmosphere only works under Lighting: borrow the place's, or add one on this screen.
	local air: Atmosphere
	if atmosphere then
		if atmosphere.Name ~= "CampAtmosphere" and not savedAtmosphere then
			savedAtmosphere = {
				Density = atmosphere.Density,
				Haze = atmosphere.Haze,
				Glare = atmosphere.Glare,
				Color = atmosphere.Color,
				Decay = atmosphere.Decay,
			}
		end
		air = atmosphere
	else
		air = Instance.new("Atmosphere")
		air.Name = "CampAtmosphere"
		air.Parent = Lighting
	end
	air.Density = c.atmosphere.density
	air.Haze = c.atmosphere.haze
	air.Glare = c.atmosphere.glare
	air.Color = rgb(c.atmosphere.color)
	air.Decay = rgb(c.atmosphere.decay)
	-- Post effects under the camera show on this screen only.
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = c.bloom.intensity
	bloom.Size = c.bloom.size
	bloom.Threshold = c.bloom.threshold
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Contrast = c.colorCorrection.contrast
	grade.Saturation = c.colorCorrection.saturation
	grade.TintColor = rgb(c.colorCorrection.tint)
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = c.sunRays.intensity
	rays.Spread = c.sunRays.spread
	for _, effect in { bloom, grade, rays } :: { Instance } do
		effect.Name = "Camp" .. effect.ClassName
		effect.Parent = Workspace.CurrentCamera
		table.insert(campEffects, effect)
	end
end

local function setInCamp(on: boolean)
	if on == inCamp then
		return
	end
	inCamp = on
	tuneAll()
	setCampLighting(on)
end

function CampLife.start()
	quality = readQuality()
	pcall(function()
		UserSettings().GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			quality = readQuality()
			tuneAll()
		end)
	end)
	task.spawn(function()
		local hub = Workspace:WaitForChild("Hub")
		hub.DescendantAdded:Connect(register)
		for _, item in hub:GetDescendants() do
			register(item)
		end
	end)
	local function onLocation()
		setInCamp(player:GetAttribute("Location") == "Camp")
	end
	player:GetAttributeChangedSignal("Location"):Connect(onLocation)
	onLocation()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		for _, effect in campEffects do
			effect.Parent = Workspace.CurrentCamera
		end
	end)

	local nextSlow = 0
	RunService.PreSimulation:Connect(function(dt)
		if not inCamp then
			return
		end
		local now = os.clock()
		local still = Ui.reducedMotion()
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local me = rootPosition()
		for i = #npcs, 1, -1 do
			local npc = npcs[i]
			if npc.model.Parent == nil then
				tracked[npc.model] = nil
				table.remove(npcs, i)
				continue
			end
			if (npc.root.Position - eye).Magnitude < ANIMATE_RANGE then
				animate(npc, now, dt, me)
			end
			local mark = npc.root:FindFirstChild("Marker")
			if mark and mark:IsA("BillboardGui") then
				local bounce = if still then 0 else math.abs(math.sin(now * 3))
				mark.StudsOffsetWorldSpace = Vector3.new(0, height(npc) + 4.2 + bounce * 0.8, 0)
				local scale = mark:FindFirstChildOfClass("UIScale")
				if scale then
					scale.Scale = if still then 1 else 1 + 0.08 * math.sin(now * 6)
				end
			end
		end
		for part, mover in movers do
			if part.Parent == nil then
				movers[part] = nil
			elseif not still then
				part.CFrame = moverCFrame(mover, now)
			end
		end
		if now >= nextSlow then
			nextSlow = now + 1 / SLOW_HZ
			for item, glow in glows do
				if item.Parent == nil then
					glows[item] = nil
				else
					setGlow(item, glowValue(glow, now))
				end
			end
		end
	end)
end

return CampLife
