--!strict
-- The camp screen (see the camp screen board on the design canvas): Rift Shard and gold pills
-- over your profile card bottom-left, the nest raid countdown top-middle, the party card while
-- you stand on a portal, and the gold beam over the portal you pinned. All of it shows only in
-- camp; out on a hunt the hunt bars take over.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hub = require(Shared:WaitForChild("Config"):WaitForChild("Hub"))
local Icons = require(Shared:WaitForChild("Config"):WaitForChild("Icons"))
local NestRotation = require(Shared:WaitForChild("Rules"):WaitForChild("NestRotation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local CampHud = {}

local player = Players.LocalPlayer
local portalById: { [string]: any } = {}
for _, portal in Hub.portals do
	portalById[portal.id] = portal
end

-- Pills over the profile card, bottom-left (top-right on phones). onPlus opens the way to earn
-- more.
local function walletAndProfile(gui: ScreenGui, onPlus: () -> ()): Frame
	local block = Ui.frame(gui, UDim2.fromOffset(300, 140))
	block.AnchorPoint = Vector2.new(0, 1)
	block.Position = UDim2.new(0, 16, 1, -16)

	local pills = Ui.frame(block, UDim2.new(1, 0, 0, 40))
	Ui.stack(pills, 8, true)
	local shards = Ui.pill(pills, Ui.colors.shard, Icons.Shard, onPlus)
	local gold = Ui.pill(pills, Ui.colors.gold, Icons.Gold, onPlus)

	local card = Ui.frame(block, UDim2.new(1, 0, 0, 88), Ui.colors.night)
	card.Position = UDim2.fromOffset(0, 52)
	card.BackgroundTransparency = 0.1
	Ui.corner(card, 12)
	Ui.stroke(card, Color3.fromRGB(43, 46, 58), 2)
	local avatar = Instance.new("ImageLabel")
	avatar.Position = UDim2.fromOffset(10, 10)
	avatar.Size = UDim2.fromOffset(68, 68)
	avatar.BackgroundColor3 = Ui.colors.raised
	avatar.BorderSizePixel = 0
	Ui.corner(avatar, 10)
	Ui.stroke(avatar, Color3.fromRGB(240, 122, 106), 2)
	avatar.Parent = card
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		if ok then
			avatar.Image = image
		end
	end)
	local name = Ui.text(card, player.DisplayName, 18, Ui.colors.text, Ui.fonts.heading, 22)
	name.AutomaticSize = Enum.AutomaticSize.None
	name.Position = UDim2.fromOffset(90, 12)
	name.Size = UDim2.new(1, -100, 0, 22)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	Ui.ink(name)
	local handle = Ui.text(card, `@{player.Name}`, 12, Ui.colors.muted, Ui.fonts.bold, 16)
	handle.AutomaticSize = Enum.AutomaticSize.None
	handle.Position = UDim2.fromOffset(90, 34)
	handle.Size = UDim2.new(1, -100, 0, 16)
	handle.TextTruncate = Enum.TextTruncate.AtEnd
	local rank = Ui.text(card, "", 13, Ui.colors.text, Ui.fonts.button, 24)
	rank.AutomaticSize = Enum.AutomaticSize.None
	rank.Position = UDim2.fromOffset(90, 54)
	rank.Size = UDim2.fromOffset(120, 24)
	rank.TextXAlignment = Enum.TextXAlignment.Center
	rank.BackgroundTransparency = 0
	rank.BackgroundColor3 = Ui.colors.rift
	Ui.corner(rank, 12)
	Ui.ink(rank)

	if Ui.touchOnly() then
		-- Phones: the thumbstick lives bottom-left, so the pills go top-right and the profile
		-- card stays hidden (the Profile tile shows it).
		block.AnchorPoint = Vector2.new(1, 0)
		block.Position = UDim2.new(1, -16, 0, 66)
		block.Size = UDim2.fromOffset(300, 40)
		card.Visible = false
	end
	Ui.fit(block)

	Ui.target("shards", shards.Parent :: GuiObject)
	Ui.target("gold", gold.Parent :: GuiObject)
	-- Numbers roll up to the new amount instead of jumping.
	local function showWallet()
		Ui.count(shards, PlayerData.shards)
		Ui.count(gold, PlayerData.gold)
	end
	PlayerData.changed:Connect(showWallet)
	showWallet()
	local function showRank()
		rank.Text = `RIFT RANK {player:GetAttribute("RiftRank") or Hub.startingRank}`
	end
	player:GetAttributeChangedSignal("RiftRank"):Connect(showRank)
	showRank()
	return block
end

local function nestWidget(gui: ScreenGui): Frame
	local box = Ui.frame(gui, UDim2.fromOffset(270, 62), Ui.colors.night)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 16)
	box.BackgroundTransparency = 0.1
	Ui.corner(box, 12)
	Ui.stroke(box, Ui.colors.rift, 3)
	Ui.fit(box)
	-- The egg's silhouette: you know which monster, not what the egg looks like.
	local egg = Ui.frame(box, UDim2.fromOffset(28, 36), Color3.fromRGB(5, 7, 10))
	egg.Position = UDim2.fromOffset(14, 13)
	Ui.corner(egg, 14)
	Ui.stroke(egg, Ui.colors.rift, 2)
	local top =
		Ui.text(box, "NEXT NEST RAID", 11, Color3.fromRGB(240, 196, 236), Ui.fonts.heading, 16)
	top.AutomaticSize = Enum.AutomaticSize.None
	top.Position = UDim2.fromOffset(56, 9)
	top.Size = UDim2.new(1, -66, 0, 16)
	local time = Ui.text(box, "", 22, Ui.colors.text, Ui.fonts.button, 28)
	time.AutomaticSize = Enum.AutomaticSize.None
	time.Position = UDim2.fromOffset(56, 25)
	time.Size = UDim2.new(1, -66, 0, 28)
	Ui.ink(time)

	local last = -1
	RunService.Heartbeat:Connect(function()
		local now = math.floor(Workspace:GetServerTimeNow())
		if now == last then
			return
		end
		last = now
		local state = NestRotation.at(Hub.nest, now)
		top.Text = if state.open
			then `{string.upper(state.egg)} EGG RAID OPEN`
			else `NEXT: {string.upper(state.egg)} EGG`
		time.Text = NestRotation.format(state.secondsLeft)
		-- The same countdown on the spire's sign in camp.
		local hub = Workspace:FindFirstChild("Hub")
		local spire = hub and hub:FindFirstChild("Stations")
		spire = spire and spire:FindFirstChild("NestSpire")
		local hunter = spire and spire:FindFirstChild("Hunter")
		local body = hunter and hunter:FindFirstChild("Root")
		local signGui = body and body:FindFirstChild("Sign")
		local sub = signGui and signGui:FindFirstChild("Subtitle")
		if sub and sub:IsA("TextLabel") then
			sub.Text = `{top.Text}  {time.Text}`
		end
	end)
	return box
end

local function partyCard(gui: ScreenGui)
	local card = Ui.frame(gui, UDim2.fromOffset(540, 184), Ui.colors.panel)
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -24)
	card.BackgroundTransparency = 0.04
	card.Visible = false
	Ui.fit(card)
	Ui.corner(card, 16)
	local stroke = Ui.stroke(card, Ui.colors.line, 3)
	Ui.padding(card, 18)

	local title = Ui.text(card, "HUNTING PARTY", 22, Ui.colors.text, Ui.fonts.heading, 28)
	title.AutomaticSize = Enum.AutomaticSize.None
	title.Size = UDim2.new(0.62, 0, 0, 28)
	title.TextTruncate = Enum.TextTruncate.AtEnd
	local countdown = Ui.text(card, "", 18, Ui.colors.gold, Ui.fonts.button, 28)
	countdown.AutomaticSize = Enum.AutomaticSize.None
	countdown.AnchorPoint = Vector2.new(1, 0)
	countdown.Position = UDim2.fromScale(1, 0)
	countdown.Size = UDim2.new(0.38, 0, 0, 28)
	countdown.TextXAlignment = Enum.TextXAlignment.Right
	Ui.ink(countdown)

	local slots = Ui.frame(card, UDim2.new(1, 0, 0, 54))
	slots.Position = UDim2.fromOffset(0, 40)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.25, -8, 1, 0)
	grid.CellPadding = UDim2.fromOffset(10, 0)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = slots
	local slotLabels: { TextLabel } = {}
	for i = 1, Hub.party.maxSize do
		local slot = Instance.new("TextLabel")
		slot.LayoutOrder = i
		slot.Font = Ui.fonts.bold
		slot.TextSize = 14
		slot.TextTruncate = Enum.TextTruncate.AtEnd
		slot.BorderSizePixel = 0
		Ui.corner(slot)
		Ui.stroke(slot, Ui.colors.line, 2)
		slot.Parent = slots
		slotLabels[i] = slot
	end

	local hint = Ui.text(
		card,
		"Step off the portal to leave the party.",
		13,
		Ui.colors.muted,
		Ui.fonts.bold,
		48
	)
	hint.AutomaticSize = Enum.AutomaticSize.None
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.fromScale(0, 1)
	hint.Size = UDim2.new(1, -180, 0, 48)
	hint.TextYAlignment = Enum.TextYAlignment.Center
	local currentPortal: string? = nil
	local go = Ui.button(card, "Go Now", "claim", function()
		if currentPortal then
			Remotes.get("PartyGo"):FireServer(currentPortal)
		end
	end)
	go.AnchorPoint = Vector2.new(1, 1)
	go.Position = UDim2.fromScale(1, 1)
	go.Size = UDim2.fromOffset(160, 48)

	Remotes.get("PartyUpdate").OnClientEvent:Connect(function(portalId, names, seconds, locked)
		local portal = portalId and portalById[portalId]
		currentPortal = if portal and names then portalId else nil
		if not portal then
			card.Visible = false
			return
		end
		local color = Color3.fromRGB(portal.color[1], portal.color[2], portal.color[3])
		stroke.Color = color
		card.Visible = true
		title.Text = string.upper(portal.displayName)
		if locked then
			countdown.Text = locked
			countdown.TextColor3 = Ui.colors.bad
			hint.Text = "This portal is locked. Check the Hunting Board for hunts you can take."
			hint.Size = UDim2.new(1, 0, 0, 48)
			go.Visible = false
			slots.Visible = false
			return
		end
		go.Visible = true
		slots.Visible = true
		countdown.Text = `Leaving in {seconds}`
		countdown.TextColor3 = Ui.colors.gold
		hint.Text = "Step off the portal to leave the party."
		hint.Size = UDim2.new(1, -180, 0, 48)
		for i, slot in slotLabels do
			local name = names[i]
			slot.Text = name or "Open"
			slot.TextColor3 = if name then Ui.colors.text else Ui.colors.disabledText
			slot.BackgroundColor3 = if name
				then color:Lerp(Color3.new(0, 0, 0), 0.65)
				else Ui.colors.inset
			local s = slot:FindFirstChildOfClass("UIStroke") :: UIStroke
			s.Color = if name then color else Ui.colors.line
		end
	end)
end

-- A tall gold beam over the pinned portal, drawn only on this player's screen.
local beam: Part? = nil
function CampHud.pin(portalId: string?)
	if beam then
		beam:Destroy()
		beam = nil
	end
	local hub = Workspace:FindFirstChild("Hub")
	local portals = hub and hub:FindFirstChild("Portals")
	local model = portalId and portals and portals:FindFirstChild(portalId)
	local pad = model and model:FindFirstChild("Pad")
	if not (pad and pad:IsA("BasePart")) then
		return
	end
	local part = Instance.new("Part")
	part.Name = "PinnedBeam"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Ui.colors.gold
	part.Transparency = 0.45
	part.Size = Vector3.new(1.5, 60, 1.5)
	part.CFrame = CFrame.new(pad.Position + Vector3.new(0, 30, 0))
	part.Parent = Workspace.CurrentCamera
	beam = part
end

-- onPlus: what the pills' + buttons open.
function CampHud.start(screen: ScreenGui, onPlus: () -> ())
	local wallet = walletAndProfile(screen, onPlus)
	local nest = nestWidget(screen)
	partyCard(screen)
	local function showLocation()
		local inCamp = player:GetAttribute("Location") == "Camp"
		wallet.Visible = inCamp
		nest.Visible = inCamp
	end
	player:GetAttributeChangedSignal("Location"):Connect(showLocation)
	showLocation()
end

return CampHud
