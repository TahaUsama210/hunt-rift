--!strict
-- Spawns the monsters listed in Config/Hunt and runs their AI on the server: chase the
-- nearest player, pick an attack with Rules/MonsterAI, tell clients with MonsterAction so they
-- animate and warn, then hurt whoever is still in the hit area when it lands.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local Hunt = require(Shared:WaitForChild("Config"):WaitForChild("Hunt"))
local MonsterAI = require(Shared:WaitForChild("Rules"):WaitForChild("MonsterAI"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MonsterRig = require(script.Parent:WaitForChild("MonsterRig"))

local MonsterController = {}

type Brain = {
	id: string,
	spawn: any,
	model: Model,
	root: BasePart,
	mover: AlignPosition,
	turner: AlignOrientation,
	ai: any,
	rig: any,
	groundY: number,
	nextGroundCheck: number,
	busyUntil: number,
	readyAt: { [string]: number },
	alive: boolean,
	-- Bumped on death so attacks scheduled before it do nothing.
	token: number,
}

local brains: { [string]: Brain } = {}
local rng = Random.new()

local folder = Instance.new("Folder")
folder.Name = "Monsters"
folder.Parent = Workspace

local function loadRig(name: string): any
	return require(Shared:WaitForChild("Rigs"):WaitForChild(name) :: ModuleScript)
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function groundBelow(position: Vector3): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -300, 0), params)
	return hit and hit.Position.Y
end

local function livingCharacters(): { { humanoid: Humanoid, root: BasePart } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			table.insert(list, { humanoid = humanoid, root = root })
		end
	end
	return list
end

-- Distance and angle from the monster to a point, in the terms Rules/MonsterAI uses.
local function measure(brain: Brain, point: Vector3): (number, number, Vector3)
	local offset = flat(point - brain.root.Position)
	local look = flat(brain.root.CFrame.LookVector)
	local angle = MonsterAI.angleTo({ x = look.X, z = look.Z }, { x = offset.X, z = offset.Z })
	return offset.Magnitude, angle, offset
end

local function hold(brain: Brain)
	local p = brain.root.Position
	brain.mover.Position = Vector3.new(p.X, brain.groundY + brain.rig.hipHeight, p.Z)
end

local function hitPlayers(brain: Brain, attack: any)
	for _, target in livingCharacters() do
		local distance, angle = measure(brain, target.root.Position)
		if MonsterAI.inHitArea(attack, distance, angle) then
			target.humanoid:TakeDamage(attack.damage)
		end
	end
end

local function startAttack(brain: Brain, name: string, now: number)
	local attack = brain.ai.attacks[name]
	brain.busyUntil, brain.readyAt[name] = MonsterAI.attackTimes(attack, now)
	hold(brain)
	local look = flat(brain.root.CFrame.LookVector).Unit
	brain.turner.CFrame = CFrame.lookAt(Vector3.zero, look)
	Remotes.get("MonsterAction"):FireAllClients(brain.id, name)

	local token = brain.token
	task.delay(attack.windup, function()
		if brain.token == token and attack.lunge > 0 then
			brain.mover.MaxVelocity = attack.lunge / attack.active
			brain.mover.Position += look * attack.lunge
		end
	end)
	task.delay(attack.windup + attack.active * 0.5, function()
		if brain.token == token then
			hitPlayers(brain, attack)
		end
	end)
end

local function think(brain: Brain, now: number)
	if now < brain.busyUntil then
		return
	end
	local ai = brain.ai
	brain.mover.MaxVelocity = ai.walkSpeed
	local position = brain.root.Position
	if now >= brain.nextGroundCheck then
		brain.groundY = groundBelow(position) or brain.groundY
		brain.nextGroundCheck = now + 0.25
	end

	local targets = livingCharacters()
	local flats = {}
	for i, t in targets do
		flats[i] = { x = t.root.Position.X, z = t.root.Position.Z }
	end
	local index = MonsterAI.nearest({ x = position.X, z = position.Z }, flats, ai.aggroRange)
	if not index then
		hold(brain)
		return
	end

	local distance, angle, offset = measure(brain, targets[index].root.Position)
	local attack = MonsterAI.pickAttack(ai, distance, angle, brain.readyAt, now, rng:NextNumber())
	if attack then
		startAttack(brain, attack, now)
		return
	end
	if distance > 0.1 then
		brain.turner.CFrame = CFrame.lookAt(Vector3.zero, offset)
	end
	local goal = if distance > ai.stopDistance
		then position + offset.Unit * (distance - ai.stopDistance)
		else position
	brain.mover.Position = Vector3.new(goal.X, brain.groundY + brain.rig.hipHeight, goal.Z)
end

local function spawnMonster(spawn: any)
	local id = spawn.monsterId
	local monster = Monsters[id]
	local rig = loadRig(monster.rig)
	local model = MonsterRig.build(rig, monster.rig)
	model.Name = id
	model:SetAttribute("MonsterId", id)
	model:SetAttribute("MaxHp", monster.maxHp)
	model:SetAttribute("Hp", monster.maxHp)
	-- Stream the whole monster at once so clients never see half a rig.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local root = model.PrimaryPart :: BasePart
	root.Anchored = true
	model.Parent = folder

	local p = spawn.position
	local groundY = groundBelow(Vector3.new(p[1], p[2], p[3])) or p[2]
	model:PivotTo(CFrame.new(p[1], groundY + rig.hipHeight, p[3]))

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local mover = Instance.new("AlignPosition")
	mover.Mode = Enum.PositionAlignmentMode.OneAttachment
	mover.Attachment0 = attachment
	mover.MaxForce = math.huge
	mover.MaxVelocity = monster.ai.walkSpeed
	mover.Responsiveness = 40
	mover.Position = root.Position
	mover.Parent = root
	local turner = Instance.new("AlignOrientation")
	turner.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turner.Attachment0 = attachment
	turner.MaxTorque = math.huge
	turner.MaxAngularVelocity = monster.ai.turnSpeed
	turner.Responsiveness = 30
	turner.CFrame = root.CFrame.Rotation
	turner.Parent = root

	root.Anchored = false
	root:SetNetworkOwner(nil)

	local old = brains[id]
	brains[id] = {
		id = id,
		spawn = spawn,
		model = model,
		root = root,
		mover = mover,
		turner = turner,
		ai = monster.ai,
		rig = rig,
		groundY = groundY,
		nextGroundCheck = 0,
		busyUntil = 0,
		readyAt = {},
		alive = true,
		token = if old then old.token + 1 else 0,
	}
end

function MonsterController.start()
	for _, spawn in Hunt.spawns do
		spawnMonster(spawn)
	end
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, brain in brains do
			if brain.alive then
				think(brain, now)
			end
		end
	end)
end

function MonsterController.isAlive(id: string): boolean
	local brain = brains[id]
	return brain ~= nil and brain.alive
end

function MonsterController.getModel(id: string): Model?
	local brain = brains[id]
	return brain and brain.model
end

function MonsterController.setHp(id: string, hp: number)
	local brain = brains[id]
	if brain then
		brain.model:SetAttribute("Hp", hp)
	end
end

-- Hides the pieces that break off with this part (the crest when the head breaks) and staggers.
function MonsterController.breakPart(id: string, part: string)
	local brain = brains[id]
	if not (brain and brain.alive) then
		return
	end
	for _, piece in brain.model:GetDescendants() do
		if piece:IsA("BasePart") and piece:GetAttribute("BreaksWith") == part then
			piece.Transparency = 1
			piece.CanQuery = false
		end
	end
	local timing = brain.rig.animations.flinch.timing
	local now = os.clock()
	brain.token += 1 -- a break interrupts whatever attack was coming
	brain.busyUntil = now + timing.windup + timing.active + timing.recovery
	hold(brain)
	Remotes.get("MonsterAction"):FireAllClients(id, "flinch")
end

function MonsterController.kill(id: string)
	local brain = brains[id]
	if not (brain and brain.alive) then
		return
	end
	brain.alive = false
	brain.token += 1
	hold(brain)
	Remotes.get("MonsterAction"):FireAllClients(id, "death")
	task.delay(Hunt.corpseSeconds, function()
		brain.model:Destroy()
	end)
	task.delay(Hunt.respawnSeconds, function()
		if brains[id] == brain then
			spawnMonster(brain.spawn)
		end
	end)
end

return MonsterController
