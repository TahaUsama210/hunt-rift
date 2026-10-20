--!strict
-- The station menus in Rift Camp. Each station's prompt (F) opens its menu; walking away or
-- the close button shuts it. The server still checks every action (crafting needs you at
-- the blacksmith), the menus only show what is possible.

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

local Stations = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local open: { panel: Ui.Panel, stationId: string, refresh: () -> () }? = nil
local inventory: Crafting.Inventory = { items = {}, gold = 0 }
local onPin: (portalId: string?) -> () = function(_: string?) end
local pinned: string? = nil

local stationById: { [string]: any } = {}
for _, station in Hub.stations do
	stationById[station.id] = station
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function close()
	if open then
		open.panel.root:Destroy()
		open = nil
	end
end

local function rank(): number
	local r = player:GetAttribute("RiftRank")
	return if typeof(r) == "number" then r else Hub.startingRank
end

local function heading(parent: Instance, text: string)
	Ui.text(parent, string.upper(text), 28, Ui.colors.text, Ui.fonts.heading, 34)
end

local function smallCaps(parent: Instance, text: string)
	Ui.text(parent, string.upper(text), 12, Ui.colors.muted, Ui.fonts.bold, 18)
end

-- The gold action pinned to the bottom-right of the details side.
local function footerButton(detail: Frame, text: string, kind: string, onClick: (() -> ())?)
	local button = Ui.button(detail, text, kind, onClick)
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.fromScale(1, 1)
	return button
end

local function body(detail: Frame): Frame
	local column = Ui.frame(detail, UDim2.new(1, 0, 1, -60))
	Ui.stack(column, 10)
	return column
end

-- Hunting Board: one contract per biome for now, until Rules/Contract rolls conditions.
local function boardMenu(panel: Ui.Panel, selected: { id: string? })
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	selected.id = selected.id or Hub.portals[1].id
	local chosen
	for _, portal in Hub.portals do
		local ok, why = PortalParty.canEnter(portal, rank())
		local monster = portal.monsterId and Monsters[portal.monsterId]
		local subtitle = if ok
			then `{portal.displayName} · Rank {portal.minRank}`
			else `{portal.displayName} · {why}`
		local title = if monster then `Hunt a {monster.displayName}` else portal.displayName
		Ui.listItem(
			panel.list,
			title,
			subtitle,
			if pinned == portal.id then "PINNED" elseif ok then nil else "LOCKED",
			if pinned == portal.id then Ui.colors.gold else Ui.colors.muted,
			selected.id == portal.id,
			function()
				selected.id = portal.id
				boardMenu(panel, selected)
			end
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
	heading(column, if monster then `Hunt a {monster.displayName}` else chosen.displayName)
	Ui.text(
		column,
		`{chosen.displayName} · Rift Rank {chosen.minRank}`,
		15,
		rgb(chosen.color),
		Ui.fonts.bold
	)
	local ok, why = PortalParty.canEnter(chosen, rank())
	if monster then
		smallCaps(column, "Likely rewards")
		local lootTable = Loot[monster.lootTable]
		local names = {}
		for _, drop in lootTable.drops do
			table.insert(names, Ui.pretty(drop.item))
		end
		Ui.text(column, table.concat(names, ", "), 15, Ui.colors.text, Ui.fonts.body, 40)
		Ui.text(
			column,
			"Step onto its portal in the north of camp. Friends who join within 10 seconds hunt with you.",
			14,
			Ui.colors.muted,
			Ui.fonts.body,
			40
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
		footerButton(panel.detail, "Pin contract", "primary", function()
			pinned = chosen.id
			onPin(chosen.id)
			boardMenu(panel, selected)
		end)
	end
end

local function shortBy(recipe: any): number
	local count = 0
	for _, n in Crafting.missing(inventory, recipe) do
		count += n
	end
	return count
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
		local recipe = Recipes[id]
		local missing = Crafting.missing(inventory, recipe)
		local short = 0
		for item, n in missing do
			if item ~= "gold" then
				short += n
			end
		end
		local ready = next(missing) == nil
		Ui.listItem(
			panel.list,
			Ui.pretty(id),
			if Weapons[id] then "Weapon" else "Armour",
			if ready then "READY" else `{short} short`,
			if ready then Ui.colors.good else Ui.colors.bad,
			selected.id == id,
			function()
				selected.id = id
				forgeMenu(panel, selected)
			end
		)
	end
	local id = selected.id
	if not id then
		return
	end
	local recipe = Recipes[id]
	local column = body(panel.detail)
	heading(column, Ui.pretty(id))
	smallCaps(column, "Materials")
	local materials = {}
	for item in recipe.materials do
		table.insert(materials, item)
	end
	table.sort(materials)
	for _, item in materials do
		Ui.costRow(column, Ui.pretty(item), inventory.items[item] or 0, recipe.materials[item])
	end
	Ui.costRow(column, "Gold", inventory.gold, recipe.gold)
	local missing = Crafting.missing(inventory, recipe)
	if next(missing) == nil then
		footerButton(panel.detail, "Craft", "primary", function()
			Remotes.get("CraftRequest"):FireServer(id)
		end)
	else
		-- Say what is missing instead of just greying the button out.
		local first, n = next(missing)
		local text = if first == "gold"
			then `Need {n} gold`
			else `Need {n} {Ui.pretty(first :: string)}`
		footerButton(panel.detail, text, "disabled")
	end
	if shortBy(recipe) > 0 then
		Ui.text(column, "Materials come from carves and part breaks on hunts.", 14, Ui.colors.muted)
	end
end

-- Upgrade Table: shows your weapon. Levels and bonus-stat rerolls come with Rules/Upgrade.
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
		"Lv 1",
		Ui.colors.muted,
		true,
		function() end
	)
	local column = body(panel.detail)
	heading(column, weapon.displayName)
	Ui.text(column, `Attack {weapon.attack}   ·   Affinity {weapon.affinity}%`, 16)
	Ui.text(
		column,
		"Wren will level weapons up (each level adds attack) and reroll the bonus stat on Rare and better gear. Coming in the gear update.",
		14,
		Ui.colors.muted,
		Ui.fonts.body,
		60
	)
	footerButton(panel.detail, "Coming soon", "disabled")
end

local function shopMenu(panel: Ui.Panel)
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local column = body(panel.detail)
	heading(column, "Token shop")
	Ui.text(
		column,
		"Every finished hunt will pay monster tokens. Pell trades them for any part of that monster, so bad luck never blocks a piece of gear for long.",
		15,
		Ui.colors.muted,
		Ui.fonts.body,
		70
	)
	footerButton(panel.detail, "Coming soon", "disabled")
end

local function nestMenu(panel: Ui.Panel)
	Ui.clear(panel.list)
	Ui.clear(panel.detail)
	local column = body(panel.detail)
	local state = NestRotation.at(Hub.nest, Workspace:GetServerTimeNow())
	heading(column, if state.open then `{state.egg} egg raid` else "Next nest raid")
	Ui.text(
		column,
		if state.open
			then `Open now, closes in {NestRotation.format(state.secondsLeft)}`
			else `{state.egg} egg in {NestRotation.format(state.secondsLeft)}`,
		18,
		Ui.colors.rift,
		Ui.fonts.bold
	)
	Ui.text(
		column,
		"Each raid features one monster's egg. Sneak into its nest, grab the egg and get out before the parent catches you. Hatched eggs become pets.",
		15,
		Ui.colors.muted,
		Ui.fonts.body,
		70
	)
	footerButton(panel.detail, "Raids open in a later update", "disabled")
end

local function openStation(stationId: string)
	close()
	local station = stationById[stationId]
	if not station then
		return
	end
	local panel = Ui.panel(gui, station.npc, station.title, rgb(station.color), close)
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
	panel.root.Parent = gui
	open = { panel = panel, stationId = stationId, refresh = refresh }
	refresh()
end

-- Shuts the menu when you walk away from its station.
local function watchDistance()
	RunService.Heartbeat:Connect(function()
		local current = open
		if not current then
			return
		end
		local folder = Workspace:FindFirstChild("Hub")
		local stations = folder and folder:FindFirstChild("Stations")
		local model = stations and stations:FindFirstChild(current.stationId)
		local hunter = model and model:FindFirstChild("Hunter")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (hunter and hunter:IsA("Model") and root and root:IsA("BasePart")) then
			close()
			return
		end
		if (hunter:GetPivot().Position - root.Position).Magnitude > Hub.stationReach + 2 then
			close()
		end
	end)
end

-- onPinChanged is told the pinned portal id (or nil) so the camp can light that portal.
function Stations.start(onPinChanged: (portalId: string?) -> (), toast: (string) -> ())
	onPin = onPinChanged
	gui = Ui.screen("StationMenus", 10)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		local stationId = prompt:GetAttribute("Station")
		if who == player and typeof(stationId) == "string" then
			openStation(stationId)
		end
	end)
	Remotes.get("InventoryChanged").OnClientEvent:Connect(function(items, gold)
		inventory = { items = items, gold = gold }
		if open then
			open.refresh()
		end
	end)
	Remotes.get("CraftResult").OnClientEvent:Connect(function(recipeId, ok)
		toast(
			if ok then `Crafted {Ui.pretty(recipeId)}!` else `Can't craft {Ui.pretty(recipeId)} yet`
		)
	end)
	Remotes.get("InventoryRequest"):FireServer()
	watchDistance()
end

return Stations
