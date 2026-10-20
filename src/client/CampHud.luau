--!strict
-- The camp screen: gold and rift rank top-left, the nest raid countdown top-middle, the party
-- card while you stand on a portal, and the gold beam over the portal you pinned.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hub = require(Shared:WaitForChild("Config"):WaitForChild("Hub"))
local NestRotation = require(Shared:WaitForChild("Rules"):WaitForChild("NestRotation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local CampHud = {}

local player = Players.LocalPlayer
local portalById: { [string]: any } = {}
for _, portal in Hub.portals do
	portalById[portal.id] = portal
end

local function chip(parent: Instance, x: number, width: number): (Frame, TextLabel)
	local frame = Ui.frame(parent, UDim2.fromOffset(width, 44), Ui.colors.panel)
	frame.Position = UDim2.fromOffset(x, 20)
	frame.BackgroundTransparency = 0.1
	Ui.corner(frame, 22)
	local label = Ui.text(frame, "", 16, Ui.colors.text, Ui.fonts.bold, 44)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.fromScale(1, 1)
	return frame, label
end

local function nestWidget(gui: ScreenGui)
	local box = Ui.frame(gui, UDim2.fromOffset(250, 58), Color3.fromRGB(36, 27, 46))
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 18)
	box.BackgroundTransparency = 0.1
	Ui.corner(box, 10)
	Ui.stroke(box, Ui.colors.rift, 1)
	-- The egg's silhouette: you know which monster, not what the egg looks like.
	local egg = Ui.frame(box, UDim2.fromOffset(26, 34), Color3.fromRGB(5, 7, 10))
	egg.Position = UDim2.fromOffset(14, 12)
	Ui.corner(egg, 13)
	Ui.stroke(egg, Color3.fromRGB(107, 74, 122))
	local top = Ui.text(box, "NEXT NEST RAID", 11, Color3.fromRGB(215, 194, 228), Ui.fonts.bold, 16)
	top.Position = UDim2.fromOffset(54, 8)
	top.Size = UDim2.new(1, -60, 0, 16)
	local time = Ui.text(box, "", 20, Ui.colors.text, Ui.fonts.heading, 26)
	time.Position = UDim2.fromOffset(54, 24)
	time.Size = UDim2.new(1, -60, 0, 26)

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
		local body = hunter and hunter:FindFirstChild("Body")
		local signGui = body and body:FindFirstChild("Sign")
		local sub = signGui and signGui:FindFirstChild("Subtitle")
		if sub and sub:IsA("TextLabel") then
			sub.Text = `{top.Text}  {time.Text}`
		end
	end)
	return box
end

local function partyCard(gui: ScreenGui)
	local card = Ui.frame(gui, UDim2.fromOffset(520, 170), Ui.colors.panel)
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -40)
	card.Visible = false
	Ui.corner(card, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = card
	Ui.padding(card, 18)

	local title = Ui.text(card, "HUNTING PARTY", 22, Ui.colors.text, Ui.fonts.heading, 28)
	title.Size = UDim2.new(0.6, 0, 0, 28)
	local countdown = Ui.text(card, "", 16, Ui.colors.muted, Ui.fonts.bold, 28)
	countdown.AnchorPoint = Vector2.new(1, 0)
	countdown.Position = UDim2.fromScale(1, 0)
	countdown.Size = UDim2.new(0.4, 0, 0, 28)
	countdown.TextXAlignment = Enum.TextXAlignment.Right

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
		Ui.corner(slot)
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Thickness = 2
		slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		slotStroke.Parent = slot
		slot.Parent = slots
		slotLabels[i] = slot
	end

	local hint = Ui.text(
		card,
		"Step off the portal to leave the party.",
		13,
		Ui.colors.muted,
		Ui.fonts.body,
		48
	)
	hint.AutomaticSize = Enum.AutomaticSize.None
	hint.Position = UDim2.fromOffset(0, 106)
	hint.Size = UDim2.new(1, -170, 0, 48)
	hint.TextYAlignment = Enum.TextYAlignment.Center
	local currentPortal: string? = nil
	local go = Ui.button(card, "Go now", "primary", function()
		if currentPortal then
			Remotes.get("PartyGo"):FireServer(currentPortal)
		end
	end)
	go.AnchorPoint = Vector2.new(1, 1)
	go.Position = UDim2.fromScale(1, 1)

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
			hint.Text = "This portal is locked. Check the Hunting Board for hunts you can take."
			go.Visible = false
			slots.Visible = false
			return
		end
		go.Visible = true
		slots.Visible = true
		countdown.Text = `Leaving in {seconds}`
		hint.Text = "Step off the portal to leave the party."
		for i, slot in slotLabels do
			local name = names[i]
			slot.Text = name or "Open"
			slot.TextColor3 = if name then Ui.colors.text else Ui.colors.disabledText
			slot.BackgroundColor3 = Ui.colors.raised
			slot.BackgroundTransparency = if name then 0 else 1
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

function CampHud.start()
	local gui = Ui.screen("CampHud", 5)
	local _, goldLabel = chip(gui, 24, 120)
	local _, rankLabel = chip(gui, 154, 150)
	goldLabel.TextColor3 = Ui.colors.gold
	goldLabel.Text = "0 gold"
	local nest = nestWidget(gui)
	partyCard(gui)

	Remotes.get("InventoryChanged").OnClientEvent:Connect(function(_, gold)
		goldLabel.Text = `{gold} gold`
	end)
	local function showRank()
		local rank = player:GetAttribute("RiftRank")
		rankLabel.Text = `RIFT RANK {rank or Hub.startingRank}`
	end
	player:GetAttributeChangedSignal("RiftRank"):Connect(showRank)
	showRank()
	-- The nest countdown only shows in camp; gold and rank stay visible everywhere.
	local function showLocation()
		nest.Visible = player:GetAttribute("Location") == "Camp"
	end
	player:GetAttributeChangedSignal("Location"):Connect(showLocation)
	showLocation()
end

return CampHud
