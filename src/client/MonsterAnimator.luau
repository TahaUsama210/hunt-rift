--!strict
-- Animates monsters on this client by writing each Motor6D's Transform every frame: a walk
-- cycle from how fast the monster moves, plus the attack, flinch and death poses from its rig.
-- Before an attack lands it lights the monster up and marks the danger area on the ground.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local Pose = require(script.Parent:WaitForChild("Pose"))

local MonsterAnimator = {}

type Track = {
	model: Model,
	root: BasePart,
	monster: any,
	rig: any,
	joints: { [string]: Motor6D },
	phase: number,
	action: string?,
	actionStart: number,
	timing: Pose.Timing?,
}

local tracks: { [Model]: Track } = {}
local WARNING = Color3.fromRGB(255, 70, 40)

local function track(model: Model)
	local monster = Monsters[model:GetAttribute("MonsterId") :: string]
	local root = model:WaitForChild("Root", 10)
	if not (monster and monster.rig and root and root:IsA("BasePart")) then
		return
	end
	local rig = require(Shared:WaitForChild("Rigs"):WaitForChild(monster.rig) :: ModuleScript)
	local joints = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			joints[d.Name] = d
		end
	end
	tracks[model] = {
		model = model,
		root = root,
		monster = monster,
		rig = rig,
		joints = joints,
		phase = 0,
		action = nil,
		actionStart = 0,
		timing = nil,
	}
end

local function marker(t: Track, attack: any): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = WARNING
	part.Transparency = 0.85
	local ground = t.root.CFrame * CFrame.new(0, 0.15 - t.rig.hipHeight, 0)
	if attack.hitArc >= 360 then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.2, attack.hitRange * 2, attack.hitRange * 2)
		part.CFrame = ground * CFrame.Angles(0, 0, math.pi / 2)
	else
		local width = 2 * attack.hitRange * math.tan(math.rad(attack.hitArc / 2)) * 0.6
		part.Size = Vector3.new(width, 0.2, attack.hitRange)
		part.CFrame = ground * CFrame.new(0, 0, -attack.hitRange / 2)
	end
	part.Parent = Workspace.CurrentCamera
	return part
end

local function telegraph(t: Track, attack: any)
	local lasts = attack.windup + attack.active
	local glow = Instance.new("Highlight")
	glow.FillColor = WARNING
	glow.OutlineColor = WARNING
	glow.FillTransparency = 1
	glow.Adornee = t.model
	glow.Parent = Workspace.CurrentCamera
	local area = marker(t, attack)
	local info = TweenInfo.new(attack.windup, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(glow, info, { FillTransparency = 0.45 }):Play()
	TweenService:Create(area, info, { Transparency = 0.45 }):Play()
	task.delay(lasts, function()
		glow:Destroy()
		area:Destroy()
	end)
end

function MonsterAnimator.play(monsterId: string, action: string)
	local folder = Workspace:FindFirstChild("Monsters")
	local model = folder and folder:FindFirstChild(monsterId)
	local t = model and tracks[model :: Model]
	if not t then
		return
	end
	local attack = t.monster.ai.attacks[action]
	local anim = t.rig.animations[action]
	if not anim then
		return
	end
	t.action = action
	t.actionStart = os.clock()
	t.timing = attack or anim.timing
	if attack then
		telegraph(t, attack)
	end
end

local function step(t: Track, dt: number, now: number)
	local gait = t.rig.gait
	local v = t.root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local walk = math.clamp(speed / t.monster.ai.walkSpeed, 0, 1)
	t.phase = (t.phase + speed * dt / gait.stepLength * math.pi * 2) % (math.pi * 2)

	local s, c = math.sin(t.phase), math.cos(t.phase)
	local stride, knee = gait.stride * walk, gait.knee * walk
	local pose: Pose.Pose = {
		HipFL = { pitch = s * stride },
		HipBR = { pitch = s * stride },
		HipFR = { pitch = -s * stride },
		HipBL = { pitch = -s * stride },
		KneeFL = { pitch = -math.max(0, c) * knee },
		KneeBR = { pitch = -math.max(0, c) * knee },
		KneeFR = { pitch = -math.max(0, -c) * knee },
		KneeBL = { pitch = -math.max(0, -c) * knee },
		Spine = {
			y = math.abs(s) * gait.bob * walk + math.sin(now * 2) * 0.06,
			roll = s * 2 * walk,
		},
		Neck = { pitch = math.sin(now * 1.1) * 3, yaw = -s * 4 * walk },
		Jaw = { pitch = -math.max(0, math.sin(now * 0.7)) * 4 },
	}
	for i, name in { "TailA", "TailB", "TailC" } do
		pose[name] =
			{ yaw = math.sin(now * 1.4 + t.phase - i * 0.7) * gait.tailSway * (0.5 + walk) }
	end

	if t.action and t.timing then
		local extra = Pose.action(t.rig.animations[t.action], t.timing, now - t.actionStart)
		if extra then
			Pose.add(pose, extra)
		else
			t.action = nil
		end
	end

	for name, motor in t.joints do
		local values = pose[name]
		motor.Transform = if values then Pose.toCFrame(values) else CFrame.identity
	end
end

function MonsterAnimator.start()
	local folder = Workspace:WaitForChild("Monsters")
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			track(child)
		end
	end)
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			task.spawn(track, child)
		end
	end
	-- PreSimulation runs after the built-in animator, so these poses win.
	RunService.PreSimulation:Connect(function(dt)
		local now = os.clock()
		for model, t in tracks do
			if model.Parent then
				step(t, dt, now)
			else
				tracks[model] = nil
			end
		end
	end)
end

return MonsterAnimator
