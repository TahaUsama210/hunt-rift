--!strict
-- Player attacks: buttons start a swing, the arm and sword animate, and while the blade is
-- moving it checks what monster part it touches. The client only reports the hit; the server
-- checks timing and reach and decides the damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared:WaitForChild("Config"):WaitForChild("Weapons"))
local Hunt = require(Shared:WaitForChild("Config"):WaitForChild("Hunt"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Pose = require(script.Parent:WaitForChild("Pose"))

local PlayerCombat = {}

local player = Players.LocalPlayer

-- Arm and waist poses per swing style. Pitch raises the arm forward, yaw swings it left.
local STYLES = {
	vertical = {
		windup = { arm = { pitch = 165 }, waist = { pitch = 8 } },
		strike = { arm = { pitch = 5 }, waist = { pitch = -12 } },
	},
	charged = {
		windup = { arm = { pitch = 175, yaw = -10 }, waist = { pitch = 12, yaw = -20 } },
		strike = { arm = { pitch = -5 }, waist = { pitch = -18, yaw = 5 } },
	},
	horizontal = {
		windup = { arm = { pitch = 35, yaw = -85 }, waist = { yaw = -35 } },
		strike = { arm = { pitch = 35, yaw = 75 }, waist = { yaw = 35 } },
	},
	thrust = {
		windup = { arm = { pitch = -20, z = 0.6 }, waist = { yaw = -15 } },
		strike = { arm = { pitch = 15, z = -1.5 }, waist = { yaw = 10 } },
	},
}

type Playing = { style: any, timing: any, started: number }
local playing: { [Model]: Playing } = {}

local function joints(character: Model): (Motor6D?, Motor6D?, boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		local arm = character:FindFirstChild("RightUpperArm")
		local torso = character:FindFirstChild("UpperTorso")
		return arm and arm:FindFirstChild("RightShoulder") :: Motor6D?,
			torso and torso:FindFirstChild("Waist") :: Motor6D?,
			true
	end
	local torso = character:FindFirstChild("Torso")
	return torso and torso:FindFirstChild("Right Shoulder") :: Motor6D?, nil, false
end

-- R6 shoulders are turned sideways, so raising the arm forward is a roll there.
local function armCFrame(v: Pose.Values, r15: boolean): CFrame
	if r15 then
		return Pose.toCFrame(v)
	end
	return CFrame.new(0, v.y or 0, v.z or 0)
		* CFrame.fromEulerAnglesYXZ(0, math.rad(v.yaw or 0), math.rad(v.pitch or 0))
end

local function play(character: Model, style: string, timing: any)
	playing[character] = { style = STYLES[style], timing = timing, started = os.clock() }
end

local function animate()
	local now = os.clock()
	for character, p in playing do
		local arm, waist, r15 = joints(character)
		local pose = Pose.action(p.style, p.timing, now - p.started)
		if not pose or not character.Parent then
			playing[character] = nil
		elseif arm then
			arm.Transform = armCFrame(pose.arm or {}, r15)
			if waist then
				waist.Transform = Pose.toCFrame(pose.waist or {})
			end
		end
	end
end

-- Monster pieces the blade box touches, closest first.
local function bladeHits(blade: BasePart, params: OverlapParams): { BasePart }
	local found =
		Workspace:GetPartBoundsInBox(blade.CFrame, blade.Size + Vector3.new(1.5, 1.5, 1), params)
	local hits = {}
	for _, part in found do
		if part:GetAttribute("Hitzone") then
			table.insert(hits, part)
		end
	end
	table.sort(hits, function(a, b)
		return (a.Position - blade.Position).Magnitude < (b.Position - blade.Position).Magnitude
	end)
	return hits
end

local busyUntil = 0

local function swing(input: string)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local weaponModel = character and character:FindFirstChild("Weapon")
	if not (character and humanoid and humanoid.Health > 0 and weaponModel) then
		return
	end
	local weaponId = weaponModel:GetAttribute("WeaponId") :: string
	local weapon = Weapons[weaponId]
	local now = os.clock()
	if not weapon or now < busyUntil then
		return
	end
	local move, timing
	for name, s in weapon.swings do
		if s.input == input then
			move, timing = name, s
		end
	end
	if not move then
		return
	end

	busyUntil = now + timing.windup + timing.active + timing.recovery
	Remotes.get("SwingStarted"):FireServer(weaponId, move)
	play(character, timing.style, timing)

	-- Slow down while swinging, then go back to normal speed once no swing is running.
	if humanoid.WalkSpeed ~= Hunt.swingWalkSpeed then
		humanoid:SetAttribute("NormalWalkSpeed", humanoid.WalkSpeed)
	end
	humanoid.WalkSpeed = Hunt.swingWalkSpeed
	task.delay(busyUntil - now, function()
		if os.clock() >= busyUntil - 0.01 then
			humanoid.WalkSpeed = humanoid:GetAttribute("NormalWalkSpeed") or 16
		end
	end)

	local blade = weaponModel:FindFirstChild("Blade")
	local monsters = Workspace:FindFirstChild("Monsters")
	if not (blade and blade:IsA("BasePart") and monsters) then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { monsters }
	local hitFrom, hitUntil = now + timing.windup, now + timing.windup + timing.active
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local t = os.clock()
		if t > hitUntil or not character.Parent then
			connection:Disconnect()
			return
		end
		if t < hitFrom then
			return
		end
		local hit = bladeHits(blade, params)[1]
		local model = hit and hit:FindFirstAncestorOfClass("Model")
		if hit and model then
			connection:Disconnect()
			Remotes.get("AttackHit"):FireServer(
				weaponId,
				move,
				model:GetAttribute("MonsterId"),
				hit:GetAttribute("Hitzone")
			)
		end
	end)
end

local KEYS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.E] = "heavy",
	[Enum.KeyCode.R] = "special",
	[Enum.KeyCode.ButtonX] = "light",
	[Enum.KeyCode.ButtonY] = "heavy",
	[Enum.KeyCode.ButtonB] = "special",
}

function PlayerCombat.start()
	UserInputService.InputBegan:Connect(function(input, typing)
		if typing then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			swing("light")
		elseif KEYS[input.KeyCode] then
			swing(KEYS[input.KeyCode])
		end
	end)
	-- Other players' swings, so everyone sees everyone attack.
	Remotes.get("PlayerSwung").OnClientEvent
		:Connect(function(other: Player, weaponId: string, move: string)
			local weapon = Weapons[weaponId]
			local timing = weapon and weapon.swings[move]
			if other.Character and timing then
				play(other.Character, timing.style, timing)
			end
		end)
	-- PreSimulation runs after the built-in animator, so the swing overrides the walk.
	RunService.PreSimulation:Connect(animate)
end

-- Button labels for the controls hint, e.g. { "Click: Wide Slash", "E: Overhead" }.
function PlayerCombat.controls(weaponId: string): { string }
	local labels = { light = "Click", heavy = "E", special = "R" }
	local order = { light = 1, heavy = 2, special = 3 }
	local lines = {}
	for move, s in Weapons[weaponId].swings do
		local words = string.gsub(move, "(%u)", " %1")
		words = string.upper(string.sub(words, 1, 1)) .. string.sub(words, 2)
		table.insert(lines, { order[s.input], `{labels[s.input]}: {words}` })
	end
	table.sort(lines, function(a, b)
		return a[1] < b[1]
	end)
	local out = {}
	for _, line in lines do
		table.insert(out, line[2])
	end
	return out
end

return PlayerCombat
