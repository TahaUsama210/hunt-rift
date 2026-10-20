--!strict
-- The station menus in Rift Camp. Each station's prompt (F) opens its menu; walking away or
-- the red X shuts it. The server still checks every action (crafting needs you at the
-- blacksmith), the menus only show what is possible.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Hub = require(Config:WaitForChild("Hub"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Loot = require(Config:WaitForChild("Loot"))
local Recipes = require(Config:WaitForChild("Recipes"))
local Weapons = require(Config:WaitForChild("Weapons"))
local HuntConfig = require(Config:WaitForChild("Hunt"))
local Rules = Shared:WaitForChild("Rules")
local Crafting = require(Rules:WaitForChild("Crafting"))
local PortalParty = require(Rules:WaitForChild("PortalParty"))
local NestRotation = require(Rules:WaitForChild("NestRotation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Stations = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local open: { root: Frame, stationId: string?, refresh: () -> () }? = nil
local onPin: (portalId: string?) -> () = function(_: string?) end
local pinned: string? = nil

local stationById: { [string]: any } = {}
for _, station in Hub.stations do
	stationById[station.id] = station
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function rank(): number
	local r = player:GetAttribute("RiftRank")
	return if typeof(r) == "number" then r else Hub.startingRank
end

local function inventory(): Crafting.Inventory
	return { items = PlayerData.items, gold = PlayerData.gold }
end

local function heading(parent: Instance, text: string, color: Color3?)
	Ui.text(parent, text, 26, color or Ui.colors.gold, Ui.fonts.heading, 32)
end

local function smallCaps(parent: Instance, text: string)
	Ui.text(parent, string.upper(text), 14, Ui.colors.text, Ui.fonts.heading, 18)
end

-- The one action, full width along the bottom of the details box.
local function footerButton(detail: Frame, text: string, kind: string, onClick: (() -> ())?)
	local button = Ui.button(detail, text, kind, onClick)
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.fromScale(0, 1)
	button.Size = UDim2.new(1, 0, 0, 50)
	return button
end

local function body(detail: Frame): Frame
	local column = Ui.frame(detail, UDim2.new(1, 0, 1, -62))
	Ui.stack(column, 10)
	return column
end

-- Hunting Board: one hunt per biome for now, until Rules/Contract rolls conditions.
local function boardMenu(panel: Ui.Panel, selected: { id: string? })
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	selected.id = selected.id or Hub.portals[1].id
	local chosen
	for _, portal in Hub.portals do
		local ok, why = PortalParty.canEnter(portal, rank())
		local monster = portal.monsterId and Monsters[portal.monsterId]
		local title = if monster then `Hunt a {monster.displayName}` else portal.displayName
		Ui.listItem(
			panel.list,
			title,
			if ok
				then `{portal.displayName} · Rank {portal.minRank}`
				else `{portal.displayName} · {why}`,
			if pinned == portal.id then "PINNED" elseif ok then nil else "LOCKED",
			if pinned == portal.id then Ui.colors.gold else Ui.colors.text,
			selected.id == portal.id,
			function()
				selected.id = portal.id
				boardMenu(panel, selected)
			end,
			if ok then "Hunt" else "Locked",
			if ok then rgb(portal.color):Lerp(Color3.new(0, 0, 0), 0.15) else Ui.colors.disabled
		)
		if selected.id == portal.id then
			chosen = portal
		end
	end
	if not chosen then
		return
	end
	local column = body(panel.detail)
	local monster = chosen.monsterId and Monsters[chosen.monsterId]
	Ui.text(column, chosen.displayName, 14, Ui.colors.muted, Ui.fonts.bold)
	heading(
		column,
		if monster then `Hunt a {monster.displayName}` else chosen.displayName,
		rgb(chosen.color)
	)
	Ui.text(column, `Rift Rank {chosen.minRank}`, 15, Ui.colors.text, Ui.fonts.bold)
	local ok, why = PortalParty.canEnter(chosen, rank())
	if monster then
		smallCaps(column, "Likely rewards")
		local names = {}
		for _, drop in Loot[monster.lootTable].drops do
			table.insert(names, Ui.pretty(drop.item))
		end
		Ui.text(column, table.concat(names, ", "), 15, Ui.colors.text, Ui.fonts.bold)
		Ui.text(
			column,
			"Step onto its portal in the north of camp. Friends who join within 10 seconds hunt with you.",
			14,
			Ui.colors.muted,
			Ui.fonts.bold
		)
	else
		Ui.text(
			column,
			"Nothing hunts here yet. This biome opens in a later update.",
			15,
			Ui.colors.muted
		)
	end
	if not ok then
		footerButton(panel.detail, why or "Locked", "disabled")
	elseif pinned == chosen.id then
		footerButton(panel.detail, "Unpin", "secondary", function()
			pinned = nil
			onPin(nil)
			boardMenu(panel, selected)
		end)
	else
		footerButton(panel.detail, "Pin Hunt", "social", function()
			pinned = chosen.id
			onPin(chosen.id)
			boardMenu(panel, selected)
		end)
	end
end

local function shortCount(missing: { [string]: number }): number
	local short = 0
	for item, n in missing do
		if item ~= "gold" then
			short += n
		end
	end
	return short
end

-- Blacksmith: every recipe, what it costs and what you still need.
local function forgeMenu(panel: Ui.Panel, selected: { id: string? })
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local ids: { string } = {}
	for id in Recipes do
		table.insert(ids, id :: string)
	end
	table.sort(ids)
	selected.id = selected.id or ids[1]
	for _, id in ids do
		local missing = Crafting.missing(inventory(), Recipes[id])
		local ready = next(missing) == nil
		Ui.listItem(
			panel.list,
			Ui.pretty(id),
			if ready then "Ready to forge" else `{shortCount(missing)} materials short`,
			if ready then "READY" else nil,
			Ui.colors.good,
			selected.id == id,
			function()
				selected.id = id
				forgeMenu(panel, selected)
			end,
			if Weapons[id] then "Weapon" else "Armour",
			if Weapons[id] then Ui.colors.orange else Ui.colors.blue
		)
	end
	local id = selected.id
	if not id then
		return
	end
	local recipe = Recipes[id]
	local column = body(panel.detail)
	Ui.text(column, if Weapons[id] then "Weapon" else "Armour", 14, Ui.colors.muted, Ui.fonts.bold)
	heading(column, Ui.pretty(id))
	smallCaps(column, "Materials")
	local materials = {}
	for item in recipe.materials do
		table.insert(materials, item)
	end
	table.sort(materials)
	for _, item in materials do
		Ui.costRow(column, Ui.pretty(item), PlayerData.items[item] or 0, recipe.materials[item])
	end
	Ui.costRow(column, "Gold", PlayerData.gold, recipe.gold)
	local missing = Crafting.missing(inventory(), recipe)
	if next(missing) == nil then
		footerButton(panel.detail, "Craft", "primary", function()
			Remotes.get("CraftRequest"):FireServer(id)
		end)
	else
		-- Say what is missing instead of just greying the button out.
		local first, n = next(missing)
		local text = if first == "gold"
			then `Need {Ui.number(n)} Gold`
			else `Need {n} {Ui.pretty(first :: string)}`
		footerButton(panel.detail, text, "disabled")
		Ui.text(
			column,
			"Materials come from carves and part breaks on hunts.",
			14,
			Ui.colors.muted,
			Ui.fonts.bold
		)
	end
end

-- Upgrade Table: shows your weapon. The upgrade tree comes with Rules/Upgrade.
local function upgradeMenu(panel: Ui.Panel)
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local weaponId = HuntConfig.startingWeapon
	local character = player.Character
	local held = character and character:FindFirstChild("Weapon")
	if held then
		local id = held:GetAttribute("WeaponId")
		if typeof(id) == "string" and Weapons[id] then
			weaponId = id
		end
	end
	local weapon = Weapons[weaponId]
	Ui.listItem(
		panel.list,
		weapon.displayName,
		"Equipped",
		"LV 1",
		Ui.colors.text,
		true,
		function() end,
		"Weapon",
		Ui.colors.orange
	)
	local column = body(panel.detail)
	heading(column, weapon.displayName)
	Ui.text(
		column,
		`Attack {weapon.attack}   ·   Affinity {weapon.affinity}%`,
		16,
		Ui.colors.text,
		Ui.fonts.bold
	)
	Ui.text(
		column,
		"Wren will open an upgrade tree for each weapon: Attack, Affinity, Element and Break branches, one Upgrade Stone per node. Coming in the gear update.",
		14,
		Ui.colors.muted,
		Ui.fonts.bold
	)
	footerButton(panel.detail, "Coming Soon", "disabled")
end

local function shopMenu(panel: Ui.Panel)
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local column = body(panel.detail)
	heading(column, "Token Shop")
	Ui.text(
		column,
		"Every finished hunt will pay monster tokens. Pell trades them for any part of that monster, so bad luck never blocks a piece of gear for long.",
		15,
		Ui.colors.muted,
		Ui.fonts.bold
	)
	footerButton(panel.detail, "Coming Soon", "disabled")
end

-- The nest raid card, also used by the Eggs tile.
function Stations.nestCard(parent: Frame)
	local column = body(parent)
	local state = NestRotation.at(Hub.nest, Workspace:GetServerTimeNow())
	Ui.text(
		column,
		if state.open then "Raid open now" else "Next nest raid",
		14,
		Ui.colors.muted,
		Ui.fonts.bold
	)
	heading(column, `{state.egg} Egg`, Ui.colors.rift)
	Ui.text(
		column,
		if state.open
			then `Closes in {NestRotation.format(state.secondsLeft)}`
			else `Opens in {NestRotation.format(state.secondsLeft)}`,
		20,
		Ui.colors.text,
		Ui.fonts.button
	)
	Ui.text(
		column,
		"Each raid features one monster's egg. Sneak into its nest, grab the egg and get out before the parent catches you. Hatched eggs become pets.",
		15,
		Ui.colors.muted,
		Ui.fonts.bold
	)
	footerButton(parent, "Raids Open Soon", "disabled")
end

local function nestMenu(panel: Ui.Panel)
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local schedule = Hub.nest
	for i, egg in schedule.eggs do
		Ui.listItem(
			panel.list,
			`{egg} Egg`,
			"Featured in turn",
			nil,
			nil,
			false,
			function() end,
			`Raid {i}`,
			Ui.colors.purple
		)
	end
	Stations.nestCard(panel.detail)
end

local function openStation(stationId: string)
	local station = stationById[stationId]
	if not station then
		return
	end
	local panel = Ui.panel(gui, station.npc, station.title, rgb(station.color), function()
		open = nil
	end)
	local selected = { id = nil :: string? }
	local refresh: () -> ()
	if station.kind == "board" then
		refresh = function()
			boardMenu(panel, selected)
		end
	elseif station.kind == "forge" then
		refresh = function()
			forgeMenu(panel, selected)
		end
	elseif station.kind == "upgrade" then
		refresh = function()
			upgradeMenu(panel)
		end
	elseif station.kind == "shop" then
		refresh = function()
			shopMenu(panel)
		end
	else
		refresh = function()
			nestMenu(panel)
		end
	end
	open = { root = panel.root, stationId = stationId, refresh = refresh }
	refresh()
end

-- Shuts a station's menu when you walk away from it.
local function watchDistance()
	RunService.Heartbeat:Connect(function()
		local current = open
		if not (current and current.stationId) then
			return
		end
		local folder = Workspace:FindFirstChild("Hub")
		local stations = folder and folder:FindFirstChild("Stations")
		local model = stations and stations:FindFirstChild(current.stationId)
		local hunter = model and model:FindFirstChild("Hunter")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local far = not (hunter and hunter:IsA("Model") and root and root:IsA("BasePart"))
			or (hunter:GetPivot().Position - root.Position).Magnitude > Hub.stationReach + 2
		if far and Ui.isOpen(current.root) then
			Ui.closeOpen()
		end
	end)
end

-- onPinChanged is told the pinned portal id (or nil) so the camp can light that portal.
function Stations.start(
	screen: ScreenGui,
	onPinChanged: (portalId: string?) -> (),
	toast: (string) -> ()
)
	gui = screen
	onPin = onPinChanged
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		local stationId = prompt:GetAttribute("Station")
		if who == player and typeof(stationId) == "string" then
			openStation(stationId)
		end
	end)
	PlayerData.changed:Connect(function()
		if open then
			open.refresh()
		end
	end)
	Remotes.get("CraftResult").OnClientEvent:Connect(function(recipeId, ok)
		toast(
			if ok then `Crafted {Ui.pretty(recipeId)}!` else `Can't craft {Ui.pretty(recipeId)} yet`
		)
	end)
	watchDistance()
end

return Stations
