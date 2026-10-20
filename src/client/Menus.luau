--!strict
-- The side menu tiles in camp and the panels they open: Gear, Quests, Codex, Eggs, Areas and
-- Skills on the left; Profile, Codes, Rewards, Lodge and Rift Pass on the right, with Store
-- and Rift Pass as wide buttons. Tiles hide while you are out on a hunt.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Hub = require(Config:WaitForChild("Hub"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Loot = require(Config:WaitForChild("Loot"))
local Recipes = require(Config:WaitForChild("Recipes"))
local DailyConfig = require(Config:WaitForChild("DailyRewards"))
local Icons = require(Config:WaitForChild("Icons"))
local PortalParty = require(Shared:WaitForChild("Rules"):WaitForChild("PortalParty"))
local NestRotation = require(Shared:WaitForChild("Rules"):WaitForChild("NestRotation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Stations = require(script.Parent:WaitForChild("Stations"))

local Menus = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local redraw: (() -> ())? = nil

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Tile colors, one per menu, matching the camp screen board.
local tint = {
	gear = Color3.fromRGB(77, 141, 245),
	quests = Color3.fromRGB(232, 71, 91),
	codex = Color3.fromRGB(43, 179, 163),
	eggs = Color3.fromRGB(160, 107, 255),
	areas = Color3.fromRGB(232, 149, 43),
	skills = Color3.fromRGB(217, 75, 192),
	profile = Color3.fromRGB(240, 122, 106),
	codes = Color3.fromRGB(108, 131, 240),
	rewards = Color3.fromRGB(224, 176, 32),
	lodge = Color3.fromRGB(63, 207, 122),
}

local function opened(draw: () -> ())
	redraw = draw
	draw()
end
local function closed()
	redraw = nil
end

-- A plain explanation for menus whose systems are not built yet.
local function comingSoon(title: string, accent: Color3, text: string)
	local modal = Ui.modal(gui, title, "Coming soon", accent, closed, Vector2.new(620, 360))
	Ui.stack(modal.body, 12)
	Ui.text(modal.body, text, 16, Ui.colors.text, Ui.fonts.bold)
	local ok = Ui.button(modal.body, "Got It", "status", Ui.closeOpen)
	ok.Size = UDim2.new(1, 0, 0, 50)
end

-- Gear: everything you carry, what drops it and what it crafts.
local function gearMenu()
	local panel = Ui.panel(gui, "Everything you have carved and crafted", "Gear", tint.gear, closed)
	local picked: string? = nil
	opened(function()
		Ui.clear(panel.list)
		Ui.clear(panel.detail)
		local names: { string } = {}
		for item in PlayerData.items do
			table.insert(names, item)
		end
		table.sort(names)
		if #names == 0 then
			Ui.text(
				panel.list,
				"Nothing yet. Hunt a monster and carve it!",
				16,
				Ui.colors.muted,
				Ui.fonts.bold
			)
			Ui.text(panel.detail, "Your bag is empty.", 16, Ui.colors.muted, Ui.fonts.bold)
			return
		end
		picked = if picked and PlayerData.items[picked] then picked else names[1]
		for _, item in names do
			Ui.listItem(
				panel.list,
				Ui.pretty(item),
				`x{PlayerData.items[item]}`,
				nil,
				nil,
				item == picked,
				function()
					picked = item
					if redraw then
						redraw()
					end
				end
			)
		end
		local item = picked :: string
		local column = Ui.frame(panel.detail, UDim2.fromScale(1, 1))
		Ui.stack(column, 10)
		Ui.text(column, Ui.pretty(item), 26, Ui.colors.gold, Ui.fonts.heading, 32)
		Ui.text(column, `You have {PlayerData.items[item]}`, 16, Ui.colors.text, Ui.fonts.bold)
		local from = {}
		for monsterId, lootTable in Loot :: { [string]: any } do
			for _, drop in lootTable.drops do
				if drop.item == item then
					table.insert(from, Ui.pretty(monsterId))
				end
			end
		end
		if #from > 0 then
			Ui.text(
				column,
				`Carved from: {table.concat(from, ", ")}`,
				14,
				Ui.colors.muted,
				Ui.fonts.bold
			)
		end
		local uses = {}
		for recipeId, recipe in Recipes :: { [string]: any } do
			if recipe.materials[item] then
				table.insert(uses, Ui.pretty(recipeId))
			end
		end
		if #uses > 0 then
			Ui.text(
				column,
				`Brannoc can forge it into: {table.concat(uses, ", ")}`,
				14,
				Ui.colors.muted,
				Ui.fonts.bold
			)
		end
	end)
end

-- Codex: every monster you can hunt, its weak spots and what it drops.
local function codexMenu()
	local panel = Ui.panel(gui, "What you know about the monsters", "Codex", tint.codex, closed)
	local ids: { string } = {}
	for id, monster in Monsters :: { [string]: any } do
		if monster.rig then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local picked = ids[1]
	opened(function()
		Ui.clear(panel.list)
		Ui.clear(panel.detail)
		for _, id in ids do
			local monster = Monsters[id]
			local home = "Unknown"
			for _, portal in Hub.portals do
				if portal.monsterId == id then
					home = portal.displayName
				end
			end
			Ui.listItem(panel.list, monster.displayName, home, nil, nil, id == picked, function()
				picked = id
				if redraw then
					redraw()
				end
			end, "Monster", tint.codex)
		end
		if not picked then
			return
		end
		local monster = Monsters[picked]
		local column = Ui.frame(panel.detail, UDim2.fromScale(1, 1))
		Ui.stack(column, 10)
		Ui.text(column, monster.displayName, 26, Ui.colors.gold, Ui.fonts.heading, 32)
		Ui.text(column, `Health {Ui.number(monster.maxHp)}`, 16, Ui.colors.text, Ui.fonts.bold)
		-- Weak spots: parts sorted by how much raw damage they take.
		local parts = {}
		for part, value in monster.hitzones do
			table.insert(parts, { part = part, value = value })
		end
		table.sort(parts, function(a, b)
			return a.value > b.value
		end)
		local lines = {}
		for _, p in parts do
			table.insert(lines, `{Ui.pretty(p.part)} {p.value}`)
		end
		Ui.text(column, "WEAK SPOTS", 14, Ui.colors.text, Ui.fonts.heading)
		Ui.text(column, table.concat(lines, "  ·  "), 15, Ui.colors.muted, Ui.fonts.bold)
		local breaks = {}
		for part in monster.breakHp or {} do
			table.insert(breaks, Ui.pretty(part))
		end
		if #breaks > 0 then
			table.sort(breaks)
			Ui.text(column, "BREAKABLE", 14, Ui.colors.text, Ui.fonts.heading)
			Ui.text(column, table.concat(breaks, ", "), 15, Ui.colors.muted, Ui.fonts.bold)
		end
		local lootTable = Loot[monster.lootTable]
		if lootTable then
			local drops = {}
			for _, drop in lootTable.drops do
				table.insert(drops, Ui.pretty(drop.item))
			end
			Ui.text(column, "DROPS", 14, Ui.colors.text, Ui.fonts.heading)
			Ui.text(column, table.concat(drops, ", "), 15, Ui.colors.muted, Ui.fonts.bold)
		end
	end)
end

local function eggsMenu()
	local modal = Ui.modal(
		gui,
		"Eggs",
		"Nest raids feature one monster's egg at a time",
		tint.eggs,
		closed,
		Vector2.new(620, 440)
	)
	Stations.nestCard(modal.body)
end

-- A big "Click to Teleport" card.
local function areaCard(
	parent: Instance,
	name: string,
	line: string,
	color: Color3,
	enabled: boolean,
	onClick: () -> ()
)
	local card = Instance.new("TextButton")
	card.Text = ""
	card.AutoButtonColor = enabled
	card.BackgroundColor3 = if enabled
		then color:Lerp(Color3.new(0, 0, 0), 0.7)
		else Ui.colors.raised
	card.BorderSizePixel = 0
	Ui.corner(card, 12)
	Ui.stroke(card, if enabled then color else Ui.colors.line, 2)
	local small = Ui.text(
		card,
		line,
		12,
		if enabled then Color3.fromRGB(213, 217, 228) else Ui.colors.muted,
		Ui.fonts.bold,
		16
	)
	small.AutomaticSize = Enum.AutomaticSize.None
	small.AnchorPoint = Vector2.new(0, 1)
	small.Position = UDim2.new(0, 0, 1, -44)
	small.TextXAlignment = Enum.TextXAlignment.Center
	local big = Ui.text(
		card,
		name,
		20,
		if enabled then Ui.colors.text else Color3.fromRGB(184, 189, 203),
		Ui.fonts.heading,
		28
	)
	big.AutomaticSize = Enum.AutomaticSize.None
	big.AnchorPoint = Vector2.new(0, 1)
	big.Position = UDim2.new(0, 0, 1, -12)
	big.TextXAlignment = Enum.TextXAlignment.Center
	Ui.ink(big)
	if enabled then
		card.Activated:Connect(onClick)
	end
	card.Parent = parent
end

-- Areas: jump to any station or open portal in camp.
local function areasMenu()
	local modal =
		Ui.modal(gui, "Areas", "Jump anywhere in camp", tint.areas, closed, Vector2.new(1100, 640))
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Ui.colors.tab
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	Ui.stack(scroll, 12)
	scroll.Parent = modal.body
	local inCamp = player:GetAttribute("Location") == "Camp"
	if not inCamp then
		Ui.text(
			scroll,
			"You are out on a hunt. Head back to camp first (the Rift Stone takes you home).",
			15,
			Ui.colors.bad,
			Ui.fonts.bold
		)
	end
	local function go(areaId: string)
		Remotes.get("Teleport"):FireServer(areaId)
		Ui.closeOpen()
	end
	local function section(title: string): Frame
		local label = Ui.text(scroll, title, 14, Ui.colors.text, Ui.fonts.heading, 20)
		label.AutomaticSize = Enum.AutomaticSize.None
		local cards = Ui.frame(scroll, UDim2.new(1, -12, 0, 0))
		cards.AutomaticSize = Enum.AutomaticSize.Y
		Ui.grid(cards, UDim2.new(0.25, -11, 0, 130), 14)
		return cards
	end
	local camp = section("CAMP")
	for _, station in Hub.stations do
		areaCard(camp, station.title, "Click to Teleport", rgb(station.color), inCamp, function()
			go(station.id)
		end)
	end
	local hunts = section("HUNTS")
	local rank = player:GetAttribute("RiftRank")
	for _, portal in Hub.portals do
		local ok, why = PortalParty.canEnter(
			portal,
			if typeof(rank) == "number" then rank else Hub.startingRank
		)
		local monster = portal.monsterId and Monsters[portal.monsterId]
		local line = if ok and monster
			then `Rank {portal.minRank} · {monster.displayName}`
			else why or "Locked"
		areaCard(hunts, portal.displayName, line, rgb(portal.color), ok and inCamp, function()
			go(portal.id)
		end)
	end
end

-- Daily rewards: the 7-day calendar.
local function rewardsMenu()
	local modal = Ui.modal(
		gui,
		"Daily Rewards",
		"Come back each day. Miss a day and the week starts again.",
		Color3.fromRGB(63, 217, 160),
		closed,
		Vector2.new(900, 560)
	)
	local subtitle = modal.header:FindFirstChild("Subtitle")
	opened(function()
		Ui.clear(modal.body)
		local daily = PlayerData.daily
		local claimedThrough = if daily.canClaim then daily.day - 1 else daily.day
		for i, reward in DailyConfig.days do
			local col = ((i - 1) % 4) + 1
			local row = if i <= 4 then 1 else 2
			local wide = i == #DailyConfig.days
			local card = Ui.frame(
				modal.body,
				UDim2.new(if wide then 0.5 else 0.25, if wide then -6 else -9, 0.5, -6),
				Ui.colors.raised
			)
			card.Position =
				UDim2.new((col - 1) * 0.25, (col - 1) * 3, (row - 1) * 0.5, (row - 1) * 6)
			Ui.corner(card, 12)
			local today = i == daily.day
			local done = i <= claimedThrough
			Ui.stroke(
				card,
				if today and daily.canClaim
					then Color3.fromRGB(63, 217, 160)
					elseif done then Ui.colors.text
					else Ui.colors.line,
				if today then 3 else 2
			)
			if wide then
				card.BackgroundColor3 = Color3.fromRGB(42, 21, 48)
			end
			Ui.padding(card, 12)
			local title = Ui.text(card, `DAY {i}`, 20, Ui.colors.text, Ui.fonts.heading, 24)
			title.AutomaticSize = Enum.AutomaticSize.None
			Ui.ink(title)
			local lines = Ui.frame(card, UDim2.new(1, 0, 0, 44))
			lines.AnchorPoint = Vector2.new(0, 1)
			lines.Position =
				UDim2.new(0, 0, 1, if (today and daily.canClaim) or done then -46 else 0)
			Ui.stack(lines, 2)
			Ui.text(lines, `+ {reward.shards} Rift Shards`, 14, Ui.colors.shard, Ui.fonts.bold, 18)
			Ui.text(lines, `+ {Ui.number(reward.gold)} Gold`, 14, Ui.colors.gold, Ui.fonts.bold, 18)
			if today and daily.canClaim then
				local claim: TextButton
				claim = Ui.button(card, "Claim", "claim", function()
					Remotes.get("DailyClaim"):FireServer()
					Ui.celebrate(gui, claim, {
						{ text = `+{reward.shards} Rift Shards`, color = Ui.colors.shard },
						{ text = `+{Ui.number(reward.gold)} Gold`, color = Ui.colors.gold },
					})
					Ui.flyTo(gui, claim, "gold", Ui.colors.gold, 8)
					Ui.flyTo(gui, claim, "shards", Ui.colors.shard, 5)
				end)
				claim.AnchorPoint = Vector2.new(0, 1)
				claim.Position = UDim2.fromScale(0, 1)
				claim.Size = UDim2.new(1, 0, 0, 40)
			elseif done then
				local tag = Ui.text(card, "Claimed!", 14, Ui.colors.ink, Ui.fonts.heading, 36)
				tag.AutomaticSize = Enum.AutomaticSize.None
				tag.AnchorPoint = Vector2.new(0, 1)
				tag.Position = UDim2.fromScale(0, 1)
				tag.BackgroundTransparency = 0
				tag.BackgroundColor3 = Color3.fromRGB(236, 238, 243)
				local inset = Instance.new("UIPadding")
				inset.PaddingLeft = UDim.new(0, 10)
				inset.Parent = tag
				Ui.corner(tag, 8)
			end
		end
	end)
	-- The countdown to tomorrow's reward ticks in the subtitle while the calendar is open.
	local last = 0
	local beat = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local daily = PlayerData.daily
		if now - last < 1 or daily.canClaim or not (subtitle and subtitle:IsA("TextLabel")) then
			return
		end
		last = now
		local left = math.max(0, daily.secondsUntilNext - (now - daily.at))
		subtitle.Text = `Next reward in {NestRotation.format(left)}. Streak: {daily.streak} days.`
	end)
	modal.root.Destroying:Connect(function()
		beat:Disconnect()
	end)
end

local function profileMenu()
	local modal =
		Ui.modal(gui, "Profile", `@{player.Name}`, tint.profile, closed, Vector2.new(620, 420))
	Ui.stack(modal.body, 10)
	opened(function()
		Ui.clear(modal.body)
		local rank = player:GetAttribute("RiftRank") or Hub.startingRank
		local carried = 0
		for _, n in PlayerData.items do
			carried += n
		end
		Ui.text(modal.body, player.DisplayName, 26, Ui.colors.gold, Ui.fonts.heading, 32)
		Ui.costRow(modal.body, "Rift Rank", rank :: number, 5)
		Ui.text(
			modal.body,
			`Gold {Ui.number(PlayerData.gold)}   ·   Rift Shards {Ui.number(PlayerData.shards)}`,
			16,
			Ui.colors.text,
			Ui.fonts.bold
		)
		Ui.text(
			modal.body,
			`Items carried {carried}   ·   Daily streak {PlayerData.daily.streak}`,
			16,
			Ui.colors.text,
			Ui.fonts.bold
		)
	end)
end

-- A wide dark button under a tile column (Store, Rift Pass), springy like the tiles.
local function wideButton(
	parent: Instance,
	name: string,
	accent: Color3,
	icon: Ui.Icon,
	tag: string?,
	onClick: () -> ()
)
	local button = Instance.new("TextButton")
	button.Text = ""
	button.Size = UDim2.new(1, 0, 0, 52)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	local holder = Ui.frame(button, UDim2.fromScale(1, 1), Color3.fromRGB(21, 22, 30))
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	Ui.corner(holder, 10)
	Ui.stroke(holder, accent:Lerp(Color3.new(1, 1, 1), 0.6), 3)
	Ui.spring(button, holder)
	local art = Ui.icon(holder, icon)
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.new(0, 26, 0.5, 0)
	art.Size = UDim2.fromOffset(38, 38)
	local label = Ui.text(holder, name, 20, Ui.colors.text, Ui.fonts.button, 52)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.Position = UDim2.fromOffset(52, 0)
	label.Size = UDim2.new(1, -60, 1, 0)
	Ui.ink(label)
	if tag then
		local chip = Ui.text(holder, tag, 10, Ui.colors.text, Ui.fonts.heading, 18)
		chip.AutomaticSize = Enum.AutomaticSize.None
		chip.Size = UDim2.fromOffset(50, 18)
		chip.AnchorPoint = Vector2.new(1, 0.5)
		chip.Position = UDim2.new(1, -10, 0.5, 0)
		chip.TextXAlignment = Enum.TextXAlignment.Center
		chip.BackgroundTransparency = 0
		chip.BackgroundColor3 = Ui.colors.purple
		Ui.corner(chip, 5)
	end
	button.Activated:Connect(onClick)
	button.Parent = parent
end

local function column(anchorRight: boolean, top: number): (Frame, Frame)
	local holder = Ui.frame(gui, UDim2.fromOffset(184, 400))
	holder.AnchorPoint = Vector2.new(if anchorRight then 1 else 0, 0)
	holder.Position = if anchorRight then UDim2.new(1, -16, 0, top) else UDim2.new(0, 16, 0, top)
	local tiles = Ui.frame(holder, UDim2.fromOffset(184, 0))
	tiles.AutomaticSize = Enum.AutomaticSize.Y
	Ui.grid(tiles, UDim2.fromOffset(87, 96), 10)
	Ui.stack(holder, 10)
	Ui.fit(holder)
	return holder, tiles
end

-- Opens the daily calendar (the currency pills' + buttons point here).
function Menus.openRewards()
	rewardsMenu()
end

function Menus.start(screen: ScreenGui)
	gui = screen
	local left, leftTiles = column(false, 110)
	Ui.tile(leftTiles, "Gear", tint.gear, Icons.Gear, gearMenu)
	Ui.tile(leftTiles, "Quests", tint.quests, Icons.Quests, function()
		comingSoon(
			"Quests",
			tint.quests,
			"Daily and weekly tasks on your hunts (break 3 parts, hunt 2 Thornjaws) that pay XP, gold and Rift Shards. Coming with the contract update."
		)
	end)
	Ui.tile(leftTiles, "Codex", tint.codex, Icons.Codex, codexMenu)
	Ui.tile(leftTiles, "Eggs", tint.eggs, Icons.Eggs, eggsMenu)
	Ui.tile(leftTiles, "Areas", tint.areas, Icons.Areas, areasMenu)
	Ui.tile(leftTiles, "Skills", tint.skills, Icons.Skills, function()
		comingSoon(
			"Skills",
			tint.skills,
			"Wren's weapon upgrade tree: Attack, Affinity, Element and Break branches, one Upgrade Stone per node. Coming in the gear update."
		)
	end)
	wideButton(left, "Store", Color3.fromRGB(201, 184, 255), Icons.Store, "DEALS", function()
		comingSoon(
			"Store",
			Ui.colors.purple,
			"Cosmetics and boosts will be sold here. Nothing that makes a hunter stronger than one who plays."
		)
	end)

	local right, rightTiles = column(true, 130)
	Ui.tile(rightTiles, "Profile", tint.profile, Icons.Profile, profileMenu)
	Ui.tile(rightTiles, "Codes", tint.codes, Icons.Codes, function()
		comingSoon("Codes", tint.codes, "Type in codes from updates and socials for free rewards.")
	end)
	local rewards = Ui.tile(rightTiles, "Rewards", tint.rewards, Icons.Rewards, rewardsMenu)
	Ui.tile(rightTiles, "Lodge", tint.lodge, Icons.Lodge, function()
		comingSoon(
			"Lodge",
			tint.lodge,
			"Hunter lodges (guilds): find a group to hunt with, or start your own."
		)
	end)
	wideButton(right, "Rift Pass", Ui.colors.gold, Icons.RiftPass, nil, function()
		comingSoon("Rift Pass", Ui.colors.gold, "A season track of rewards you unlock by playing.")
	end)

	local function showFor()
		local inCamp = player:GetAttribute("Location") == "Camp"
		left.Visible = inCamp
		right.Visible = inCamp
	end
	player:GetAttributeChangedSignal("Location"):Connect(showFor)
	showFor()

	PlayerData.changed:Connect(function()
		rewards.badge(PlayerData.daily.canClaim)
		if redraw then
			redraw()
		end
	end)
	-- When the next daily reward unlocks, ask the server again so the Rewards badge lights up.
	local last = 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - last > 1 and not PlayerData.daily.canClaim then
			last = now
			local daily = PlayerData.daily
			if daily.secondsUntilNext - (now - daily.at) <= 0 then
				Remotes.get("InventoryRequest"):FireServer()
				PlayerData.daily.secondsUntilNext = math.huge
			end
		end
	end)
end

return Menus
