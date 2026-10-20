--!strict
-- Rift Camp on the server: builds it, tracks who stands on which portal, sends parties to
-- the hunting ground and brings them back. Party rules live in Rules/PortalParty.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hub = require(Shared:WaitForChild("Config"):WaitForChild("Hub"))
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local PortalParty = require(Shared:WaitForChild("Rules"):WaitForChild("PortalParty"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local HubWorld = require(script.Parent:WaitForChild("HubWorld"))

local HubServer = {}

local CAMP = "Camp"
local TICK = 0.25

local built: HubWorld.Built
local parties: { [string]: PortalParty.Party } = {}
local portalById: { [string]: any } = {}
local ranks: { [Player]: number } = {}
-- What each player was last told, so the party card is only re-sent when it changes.
local lastSent: { [Player]: string } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function groundBelow(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, name in { "Hub", "Monsters" } do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -300, 0), params)
	return if hit then hit.Position else position
end

local function sendTo(player: Player, where: CFrame, location: string)
	local character = player.Character
	if not character then
		return
	end
	player:SetAttribute("Location", location)
	character:PivotTo(where + Vector3.new(0, 3, 0))
end

local function campPosition(): CFrame
	return built.spawn.CFrame + Vector3.new(0, 1, 0)
end

-- Sends a party to its portal's hunting ground, spread out a little so nobody stacks.
local function launch(portal: any, members: { Player })
	local arrival =
		groundBelow(Vector3.new(portal.arrival[1], portal.arrival[2], portal.arrival[3]))
	for i, player in members do
		local offset = Vector3.new((i - (#members + 1) / 2) * 4, 0, 0)
		local monster = Monsters[portal.monsterId]
		print(`{player.Name} enters {portal.displayName} to hunt {monster and monster.displayName}`)
		sendTo(
			player,
			CFrame.new(arrival + offset, arrival + offset + Vector3.new(0, 0, -1)),
			portal.id
		)
	end
end

local function onPad(padAt: Vector3, radius: number): { Player }
	local here = {}
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and player:GetAttribute("Location") == CAMP then
			local flat = Vector3.new(root.Position.X - padAt.X, 0, root.Position.Z - padAt.Z)
			if flat.Magnitude <= radius and math.abs(root.Position.Y - padAt.Y) < 8 then
				table.insert(here, player)
			end
		end
	end
	return here
end

local function tell(
	player: Player,
	portalId: string?,
	names: { string }?,
	seconds: number?,
	locked: string?
)
	local key = `{portalId}|{names and table.concat(names, ",")}|{seconds}|{locked}`
	if lastSent[player] == key then
		return
	end
	lastSent[player] = key
	Remotes.get("PartyUpdate"):FireClient(player, portalId, names, seconds, locked)
end

local function tick()
	local now = os.clock()
	local told: { [Player]: boolean } = {}
	for _, portal in Hub.portals do
		local padAt = built.portals[portal.id]
		local standing = onPad(padAt, Hub.party.padRadius * (portal.size or 1))
		local allowed: { string } = {}
		local byId: { [string]: Player } = {}
		for _, player in standing do
			local ok, why = PortalParty.canEnter(portal, ranks[player] or Hub.startingRank)
			if ok then
				local id = tostring(player.UserId)
				table.insert(allowed, id)
				byId[id] = player
			else
				tell(player, portal.id, nil, nil, why)
				told[player] = true
			end
		end

		local party, leave =
			PortalParty.step(parties[portal.id] or PortalParty.new(), allowed, now, Hub.party)
		local members: { Player } = {}
		local names: { string } = {}
		for _, id in party.members do
			table.insert(members, byId[id])
			table.insert(names, byId[id].DisplayName)
		end
		if leave then
			parties[portal.id] = PortalParty.new()
			launch(portal, members)
		else
			parties[portal.id] = party
			local seconds = PortalParty.secondsLeft(party, now, Hub.party)
			for _, player in members do
				tell(player, portal.id, names, seconds, nil)
				told[player] = true
			end
		end
	end
	for _, player in Players:GetPlayers() do
		if not told[player] then
			tell(player, nil, nil, nil, nil)
		end
	end
end

-- True if the player is standing at this station, so its menu actions are allowed.
function HubServer.isAtStation(player: Player, stationId: string): boolean
	local root = rootOf(player)
	local at = built and built.stations[stationId]
	if not (root and at) then
		return false
	end
	return (root.Position - at).Magnitude <= Hub.stationReach
end

-- Everyone out on a hunt for this monster: they share its rewards.
function HubServer.huntersOf(monsterId: string): { Player }
	local hunters = {}
	for _, player in Players:GetPlayers() do
		local portal = portalById[player:GetAttribute("Location") :: any]
		if portal and portal.monsterId == monsterId then
			table.insert(hunters, player)
		end
	end
	return hunters
end

-- Brings these hunters back to camp after a short wait (the rewards moment). Anyone who
-- already walked home or left another way is skipped.
function HubServer.returnHunters(hunters: { Player }, delaySeconds: number)
	local from: { [Player]: any } = {}
	for _, player in hunters do
		from[player] = player:GetAttribute("Location")
	end
	task.delay(delaySeconds, function()
		for player, location in from do
			if player.Parent == Players and player:GetAttribute("Location") == location then
				sendTo(player, campPosition(), CAMP)
			end
		end
	end)
end

-- Where the Areas menu drops you: in front of a station's counter, or onto a portal's pad.
local function areaPosition(areaId: string, player: Player): CFrame?
	local origin = Vector3.new(Hub.origin[1], Hub.origin[2], Hub.origin[3])
	local stationAt = built.stations[areaId]
	if stationAt then
		local toMiddle = Vector3.new(origin.X - stationAt.X, 0, origin.Z - stationAt.Z)
		local dir = if toMiddle.Magnitude > 0.1 then toMiddle.Unit else Vector3.new(0, 0, 1)
		local at = stationAt + dir * 8
		return CFrame.lookAt(at, stationAt)
	end
	local portal = portalById[areaId]
	if portal and PortalParty.canEnter(portal, ranks[player] or Hub.startingRank) then
		local padAt = built.portals[areaId]
		return CFrame.lookAt(padAt, Vector3.new(origin.X, padAt.Y, origin.Z))
	end
	return nil
end

-- A stone at each hunting ground's arrival point that takes you home.
local function buildReturnStones()
	local folder = Instance.new("Folder")
	folder.Name = "ReturnStones"
	local done: { [string]: boolean } = {}
	for _, portal in Hub.portals do
		local key = table.concat(portal.arrival, ",")
		if portal.monsterId and not done[key] then
			done[key] = true
			local at =
				groundBelow(Vector3.new(portal.arrival[1], portal.arrival[2], portal.arrival[3]))
			local stone = Instance.new("Part")
			stone.Name = "ReturnStone"
			stone.Anchored = true
			stone.Size = Vector3.new(2.5, 6, 2.5)
			stone.CFrame = CFrame.new(at + Vector3.new(0, 3, 8))
			stone.Color = Color3.fromRGB(224, 91, 208)
			stone.Material = Enum.Material.Neon
			stone.Parent = folder
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Rift Stone"
			prompt.ActionText = "Return to camp"
			prompt.HoldDuration = 1
			prompt.RequiresLineOfSight = false
			prompt.Parent = stone
			prompt.Triggered:Connect(function(player)
				sendTo(player, campPosition(), CAMP)
			end)
		end
	end
	folder.Parent = Workspace
end

function HubServer.start()
	local open: { [string]: boolean } = {}
	for _, portal in Hub.portals do
		portalById[portal.id] = portal
		open[portal.id] = PortalParty.canEnter(portal, math.huge)
	end
	built = HubWorld.build(Hub, open)
	-- Everyone spawns in camp: switch off any other spawn the place has.
	for _, item in Workspace:GetDescendants() do
		if item:IsA("SpawnLocation") and item ~= built.spawn then
			item.Enabled = false
		end
	end
	buildReturnStones()

	local function onPlayer(player: Player)
		ranks[player] = Hub.startingRank
		player:SetAttribute("RiftRank", Hub.startingRank)
		player:SetAttribute("Location", CAMP)
		-- Respawning always puts you back in camp.
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Location", CAMP)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ranks[player] = nil
		lastSent[player] = nil
	end)

	-- Areas menu: only works in camp, and only to stations and portals you may use.
	Remotes.get("Teleport").OnServerEvent:Connect(function(player, areaId)
		if typeof(areaId) ~= "string" or player:GetAttribute("Location") ~= CAMP then
			return
		end
		local where = areaPosition(areaId, player)
		if where then
			sendTo(player, where, CAMP)
		end
	end)

	Remotes.get("PartyGo").OnServerEvent:Connect(function(player, portalId)
		local party = if typeof(portalId) == "string" then parties[portalId] else nil
		if party then
			parties[portalId] = PortalParty.pressGo(party, tostring(player.UserId))
		end
	end)

	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since >= TICK then
			since = 0
			tick()
		end
	end)
end

return HubServer
