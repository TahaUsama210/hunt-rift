--!strict
-- Client entry point: input and swings, monster animation, the on-screen bars, and the camp
-- screen and station menus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local Hunt = require(Shared:WaitForChild("Config"):WaitForChild("Hunt"))
local Hud = require(script:WaitForChild("Hud"))
local MonsterAnimator = require(script:WaitForChild("MonsterAnimator"))
local PlayerCombat = require(script:WaitForChild("PlayerCombat"))
local CampHud = require(script:WaitForChild("CampHud"))
local Stations = require(script:WaitForChild("Stations"))

Hud.start(PlayerCombat.controls(Hunt.startingWeapon))
MonsterAnimator.start()
PlayerCombat.start()
CampHud.start()
Stations.start(CampHud.pin, Hud.toast)

local function displayName(monsterId: string): string
	local monster = Monsters[monsterId]
	return if monster then monster.displayName else monsterId
end

-- Where on the monster a hitzone is, for the damage number.
local function hitzonePosition(monsterId: string, part: string): Vector3?
	local folder = Workspace:FindFirstChild("Monsters")
	local model = folder and folder:FindFirstChild(monsterId)
	if not model then
		return nil
	end
	for _, piece in model:GetChildren() do
		if piece:IsA("BasePart") and piece:GetAttribute("Hitzone") == part then
			return piece.Position
		end
	end
	return nil
end

Remotes.get("MonsterAction").OnClientEvent:Connect(function(monsterId, action)
	MonsterAnimator.play(monsterId, action)
end)

Remotes.get("DamageDealt").OnClientEvent:Connect(function(monsterId, part, total, crit, hpLeft)
	local position = hitzonePosition(monsterId, part)
	if position then
		Hud.damageNumber(position, total, crit)
	end
	print(`[hit] {monsterId} {part} -{total} {crit} (hp {hpLeft})`)
end)

Remotes.get("PartBroken").OnClientEvent:Connect(function(monsterId, part)
	Hud.toast(`{displayName(monsterId)}'s {part} broke!`)
end)

Remotes.get("HuntComplete").OnClientEvent:Connect(function(monsterId, rewards)
	Hud.toast(`{displayName(monsterId)} slain! Rewards: {table.concat(rewards, ", ")}`, 6)
end)

print("MonsterHunt client ready")
