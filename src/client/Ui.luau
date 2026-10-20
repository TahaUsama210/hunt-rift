--!strict
-- The UI kit: colors, fonts and the building blocks every menu uses, so all screens share one
-- look (see the UI kit board on the Hunt Rift hub and UI design canvas).

local Players = game:GetService("Players")

local Ui = {}

-- Every element gets the next LayoutOrder, so stacked items show in the order they were made.
local nextLayout = 0
local function nextOrder(): number
	nextLayout += 1
	return nextLayout
end

Ui.colors = {
	night = Color3.fromRGB(14, 18, 23),
	panel = Color3.fromRGB(28, 35, 44),
	raised = Color3.fromRGB(37, 48, 58),
	line = Color3.fromRGB(46, 57, 70),
	text = Color3.fromRGB(238, 242, 245),
	muted = Color3.fromRGB(154, 167, 180),
	gold = Color3.fromRGB(242, 169, 59),
	goldText = Color3.fromRGB(26, 18, 6),
	teal = Color3.fromRGB(60, 198, 184),
	good = Color3.fromRGB(79, 209, 107),
	bad = Color3.fromRGB(255, 138, 142),
	rift = Color3.fromRGB(224, 91, 208),
	disabled = Color3.fromRGB(42, 49, 57),
	disabledText = Color3.fromRGB(142, 153, 165),
}

Ui.fonts = {
	heading = Enum.Font.Oswald,
	body = Enum.Font.Gotham,
	bold = Enum.Font.GothamBold,
}

function Ui.screen(name: string, order: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = order or 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Ui.corner(item: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = item
end

function Ui.stroke(item: GuiObject, color: Color3, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = item
end

function Ui.padding(item: GuiObject, pixels: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, pixels)
	pad.PaddingRight = UDim.new(0, pixels)
	pad.PaddingTop = UDim.new(0, pixels)
	pad.PaddingBottom = UDim.new(0, pixels)
	pad.Parent = item
end

-- Stacks children top to bottom (or left to right) with a gap.
function Ui.stack(item: GuiObject, gap: number, horizontal: boolean?)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = if horizontal
		then Enum.FillDirection.Horizontal
		else Enum.FillDirection.Vertical
	layout.Parent = item
end

function Ui.frame(parent: Instance, size: UDim2, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.BackgroundColor3 = color or Ui.colors.panel
	frame.BackgroundTransparency = if color then 0 else 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = nextOrder()
	frame.Parent = parent
	return frame
end

function Ui.text(
	parent: Instance,
	text: string,
	size: number,
	color: Color3?,
	font: Enum.Font?,
	height: number?
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height or size + 6)
	label.Font = font or Ui.fonts.body
	label.TextSize = size
	label.TextColor3 = color or Ui.colors.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = nextOrder()
	label.Text = text
	label.Parent = parent
	return label
end

-- kind: "primary" (gold, the one action on a screen), "secondary" (outlined) or "disabled"
-- (says what is missing). Buttons are 48 px tall so they work with a thumb.
function Ui.button(parent: Instance, text: string, kind: string, onClick: (() -> ())?): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = kind ~= "disabled"
	button.Size = UDim2.fromOffset(math.max(140, #text * 11 + 48), 48)
	button.Font = Ui.fonts.heading
	button.TextSize = 20
	button.Text = string.upper(text)
	button.BorderSizePixel = 0
	button.LayoutOrder = nextOrder()
	if kind == "primary" then
		button.BackgroundColor3 = Ui.colors.gold
		button.TextColor3 = Ui.colors.goldText
	elseif kind == "disabled" then
		button.BackgroundColor3 = Ui.colors.disabled
		button.TextColor3 = Ui.colors.disabledText
	else
		button.BackgroundColor3 = Ui.colors.panel
		button.TextColor3 = Ui.colors.text
		Ui.stroke(button, Ui.colors.line)
	end
	Ui.corner(button)
	if onClick and kind ~= "disabled" then
		button.Activated:Connect(onClick)
	end
	button.Parent = parent
	return button
end

-- "ThornjawScale" -> "Thornjaw Scale"
function Ui.pretty(id: string): string
	return (string.gsub(id, "(%l)(%u)", "%1 %2"))
end

function Ui.clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

export type Panel = {
	root: Frame,
	list: ScrollingFrame,
	detail: Frame,
	header: Frame,
}

-- The station frame: the hunter's name and the station top-left, close top-right, a list on
-- the left and details on the right. Covers the middle of the screen.
function Ui.panel(
	gui: ScreenGui,
	npcName: string,
	title: string,
	accent: Color3,
	onClose: () -> ()
): Panel
	local root = Ui.frame(gui, UDim2.fromScale(0.8, 0.8), Ui.colors.panel)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	Ui.corner(root, 12)
	Ui.stroke(root, Ui.colors.line, 1)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(1024, 600)
	limit.Parent = root

	local header = Ui.frame(root, UDim2.new(1, 0, 0, 76))
	Ui.padding(header, 14)
	local who = Ui.text(header, npcName, 14, accent, Ui.fonts.bold, 18)
	who.Position = UDim2.fromOffset(10, 0)
	local name = Ui.text(header, string.upper(title), 26, Ui.colors.text, Ui.fonts.heading, 30)
	name.Position = UDim2.fromOffset(10, 18)
	local close = Ui.button(header, "X", "secondary", onClose)
	close.Size = UDim2.fromOffset(48, 48)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Name = "Close"
	local rule = Ui.frame(root, UDim2.new(1, 0, 0, 1), Ui.colors.line)
	rule.Position = UDim2.fromOffset(0, 76)

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(0, 77)
	list.Size = UDim2.new(0.38, 0, 1, -77)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	Ui.padding(list, 16)
	Ui.stack(list, 10)
	list.Parent = root
	local split = Ui.frame(root, UDim2.new(0, 1, 1, -77), Ui.colors.line)
	split.Position = UDim2.new(0.38, 0, 0, 77)

	local detail = Ui.frame(root, UDim2.new(0.62, -1, 1, -77))
	detail.Position = UDim2.new(0.38, 1, 0, 77)
	Ui.padding(detail, 24)
	return { root = root, list = list, detail = detail, header = header }
end

-- A row in a panel's list: a bold name, a grey line under it and an optional right-hand tag.
function Ui.listItem(
	parent: Instance,
	title: string,
	subtitle: string,
	tag: string?,
	tagColor: Color3?,
	selected: boolean,
	onClick: () -> ()
): TextButton
	local row = Instance.new("TextButton")
	row.AutoButtonColor = true
	row.Text = ""
	row.Size = UDim2.new(1, 0, 0, 64)
	row.LayoutOrder = nextOrder()
	row.BackgroundColor3 = Ui.colors.raised
	row.BorderSizePixel = 0
	Ui.corner(row, 10)
	if selected then
		Ui.stroke(row, Ui.colors.gold)
	end
	Ui.padding(row, 12)
	local name = Ui.text(row, title, 16, Ui.colors.text, Ui.fonts.bold, 20)
	name.Size = UDim2.new(1, -90, 0, 20)
	local sub = Ui.text(row, subtitle, 13, Ui.colors.muted, Ui.fonts.body, 18)
	sub.Position = UDim2.fromOffset(0, 22)
	if tag then
		local tagLabel = Ui.text(row, tag, 13, tagColor or Ui.colors.muted, Ui.fonts.bold, 20)
		tagLabel.Size = UDim2.new(0, 90, 0, 20)
		tagLabel.AnchorPoint = Vector2.new(1, 0)
		tagLabel.Position = UDim2.fromScale(1, 0)
		tagLabel.TextXAlignment = Enum.TextXAlignment.Right
	end
	row.Activated:Connect(onClick)
	row.Parent = parent
	return row
end

-- A "name ... have / need" line, green when there is enough.
function Ui.costRow(parent: Instance, name: string, have: number, need: number): Frame
	local row = Ui.frame(parent, UDim2.new(1, 0, 0, 40), Ui.colors.raised)
	Ui.corner(row)
	Ui.padding(row, 10)
	Ui.text(row, name, 15, Ui.colors.text, Ui.fonts.body, 20)
	local count = Ui.text(
		row,
		`{have} / {need}`,
		15,
		if have >= need then Ui.colors.good else Ui.colors.bad,
		Ui.fonts.bold,
		20
	)
	count.TextXAlignment = Enum.TextXAlignment.Right
	return row
end

return Ui
