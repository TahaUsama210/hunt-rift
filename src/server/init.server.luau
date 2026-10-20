--!strict
-- Server entry point. Holds hunt state and applies the pure rules from Shared/Rules.
-- Clients only say what they hit; the server decides the damage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Rules = Shared:WaitForChild("Rules")

local Monsters = require(Config:WaitForChild("Monsters"))
local Weapons = require(Config:WaitForChild("Weapons"))
local Combat = require(Config:WaitForChild("Combat"))
local Loot = require(Config:WaitForChild("Loot"))
local Recipes = require(Config:WaitForChild("Recipes"))
local Hunt = require(Config:WaitForChild("Hunt"))
local Damage = require(Rules:WaitForChild("Damage"))
local Parts = require(Rules:WaitForChild("Parts"))
local LootRoll = require(Rules:WaitForChild("LootRoll"))
local Crafting = require(Rules:WaitForChild("Crafting"))
local Swing = require(Rules:WaitForChild("Swing"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MonsterController = require(script:WaitForChild("MonsterController"))
local Loadout = require(script:WaitForChild("Loadout"))
local HubServer = require(script:WaitForChild("Hub"))
local HubConfig = require(Config:WaitForChild("Hub"))

Remotes.setup()
Loadout.start(Hunt)
MonsterController.start()
HubServer.start()

local rng = Random.new()
local function roll(): number
	return rng:NextNumber()
end

type Hunt = { hp: number, partDamage: { [string]: number }, broken: { string } }
local hunts: { [string]: Hunt } = {}
local inventories: { [Player]: Crafting.Inventory } = {}
local swings: { [Player]: Swing.State } = {}

local function getHunt(monsterId: string): Hunt
	local hunt = hunts[monsterId]
	if not hunt then
		hunt = { hp = Monsters[monsterId].maxHp, partDamage = {}, broken = {} }
		hunts[monsterId] = hunt
	end
	return hunt
end

local function sendInventory(player: Player)
	local inventory = inventories[player]
	if inventory then
		Remotes.get("InventoryChanged"):FireClient(player, inventory.items, inventory.gold)
	end
end

Players.PlayerAdded:Connect(function(player)
	inventories[player] = { items = {}, gold = 500 }
end)
Remotes.get("InventoryRequest").OnServerEvent:Connect(sendInventory)
Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil
	swings[player] = nil
end)

-- Distance from a point to the nearest edge of a part's box (0 if inside).
local function distanceToPart(part: BasePart, point: Vector3): number
	local p = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	local closest = Vector3.new(
		math.clamp(p.X, -h.X, h.X),
		math.clamp(p.Y, -h.Y, h.Y),
		math.clamp(p.Z, -h.Z, h.Z)
	)
	return (p - closest).Magnitude
end

-- How close the player is to any piece of the monster that counts as this hitzone.
local function reachTo(player: Player, monsterId: string, part: string): number
	local model = MonsterController.getModel(monsterId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (model and root and root:IsA("BasePart")) then
		return math.huge
	end
	local best = math.huge
	for _, piece in model:GetChildren() do
		if piece:IsA("BasePart") and piece:GetAttribute("Hitzone") == part then
			best = math.min(best, distanceToPart(piece, root.Position))
		end
	end
	return best
end

Remotes.get("SwingStarted").OnServerEvent:Connect(function(player, weaponId, moveName)
	local weapon = Weapons[weaponId]
	if not (weapon and Loadout.weaponOf(player) == weaponId and weapon.swings[moveName]) then
		return
	end
	local now = os.clock()
	if not Swing.canStart(swings[player], now, Hunt.lagGraceSeconds) then
		return
	end
	swings[player] = Swing.start(weapon.swings[moveName], moveName, now)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.get("PlayerSwung"):FireClient(other, player, weaponId, moveName)
		end
	end
end)

Remotes.get("AttackHit").OnServerEvent:Connect(function(player, weaponId, moveName, monsterId, part)
	-- Never trust the client: check every id against config before using it.
	local weapon = Weapons[weaponId]
	local monster = Monsters[monsterId]
	if not (weapon and monster and weapon.moves[moveName] and monster.hitzones[part]) then
		return
	end
	-- The player must hold this weapon, be mid-swing with this move, and be close enough.
	local swing = swings[player]
	if Loadout.weaponOf(player) ~= weaponId then
		return
	end
	if not Swing.canHit(swing, moveName, os.clock(), Hunt.lagGraceSeconds) then
		return
	end
	if not MonsterController.isAlive(monsterId) then
		return
	end
	if reachTo(player, monsterId, part) > weapon.swings[moveName].reach + Hunt.lagGraceStuds then
		return
	end
	(swing :: Swing.State).hasHit = true

	local hunt = getHunt(monsterId)
	if hunt.hp <= 0 then
		return
	end
	local hit = Damage.computeHit(weapon, moveName, monster, part, Combat, roll())
	hunt.hp = math.max(0, hunt.hp - hit.total)

	local newlyBroken
	hunt.partDamage, newlyBroken = Parts.applyPartDamage(monster, hunt.partDamage, part, hit.total)
	for _, brokenPart in newlyBroken do
		table.insert(hunt.broken, brokenPart)
		MonsterController.breakPart(monsterId, brokenPart)
		Remotes.get("PartBroken"):FireAllClients(monsterId, brokenPart)
	end

	MonsterController.setHp(monsterId, hunt.hp)
	Remotes.get("DamageDealt"):FireAllClients(monsterId, part, hit.total, hit.crit, hunt.hp)

	if hunt.hp == 0 then
		local rewards = LootRoll.rollRewards(Loot[monster.lootTable], hunt.broken, roll)
		-- Everyone out on the hunt shares the rewards; hunters still in camp get nothing.
		for _, other in Players:GetPlayers() do
			local inventory = inventories[other]
			if inventory and other:GetAttribute("Location") ~= "Camp" then
				for _, item in rewards do
					inventory.items[item] = (inventory.items[item] or 0) + 1
				end
				sendInventory(other)
			end
		end
		Remotes.get("HuntComplete"):FireAllClients(monsterId, rewards)
		HubServer.returnHunters(HubConfig.returnSeconds)
		MonsterController.kill(monsterId)
		hunts[monsterId] = nil
	end
	print(`{player.Name} hit {monsterId} {part} for {hit.total} ({hit.crit})`)
end)

Remotes.get("CraftRequest").OnServerEvent:Connect(function(player, recipeId)
	local recipe = Recipes[recipeId]
	local inventory = inventories[player]
	-- Crafting only happens at the blacksmith, not from anywhere in the world.
	if not (recipe and inventory and HubServer.isAtStation(player, "Blacksmith")) then
		return
	end
	local crafted = Crafting.craft(inventory, recipe, recipeId)
	if crafted then
		inventories[player] = crafted
		sendInventory(player)
	end
	Remotes.get("CraftResult")
		:FireClient(player, recipeId, crafted ~= nil, Crafting.missing(inventory, recipe))
end)

print("MonsterHunt server ready")
