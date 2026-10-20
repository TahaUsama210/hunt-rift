--!strict
-- The UI kit: colors, fonts and the building blocks every menu uses, so all screens share one
-- chunky look (see the UI kit board on the Hunt Rift hub and UI design canvas): near-black
-- panels with a glowing colored border, white caps titles, a red X, bright buttons with
-- outlined text, menu tiles with a colored name strip, and currency pills.

local Players = game:GetService("Players")

local Ui = {}

Ui.colors = {
	night = Color3.fromRGB(13, 14, 20),
	panel = Color3.fromRGB(13, 14, 20),
	raised = Color3.fromRGB(23, 25, 37),
	inset = Color3.fromRGB(16, 17, 26),
	line = Color3.fromRGB(58, 61, 76),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(163, 168, 184),
	ink = Color3.fromRGB(20, 21, 28),
	gold = Color3.fromRGB(255, 194, 74),
	shard = Color3.fromRGB(111, 211, 255),
	good = Color3.fromRGB(63, 207, 106),
	bad = Color3.fromRGB(255, 138, 142),
	orange = Color3.fromRGB(255, 159, 67),
	tab = Color3.fromRGB(255, 122, 69),
	purple = Color3.fromRGB(123, 108, 246),
	blue = Color3.fromRGB(79, 182, 245),
	red = Color3.fromRGB(239, 64, 88),
	rift = Color3.fromRGB(224, 91, 208),
	disabled = Color3.fromRGB(58, 60, 72),
	disabledText = Color3.fromRGB(163, 168, 184),
}

Ui.fonts = {
	heading = Enum.Font.GothamBlack,
	body = Enum.Font.GothamMedium,
	bold = Enum.Font.GothamBold,
	button = Enum.Font.FredokaOne,
}

-- Button kinds and their fill: claim = take it, primary = spend, social = party and friends,
-- status = in progress, secondary = everything else.
local buttonColors = {
	claim = Ui.colors.good,
	primary = Ui.colors.orange,
	social = Ui.colors.purple,
	status = Ui.colors.blue,
	close = Ui.colors.red,
	secondary = Ui.colors.disabled,
	disabled = Ui.colors.disabled,
}

-- Every element gets the next LayoutOrder, so stacked items show in the order they were made.
local nextLayout = 0
local function nextOrder(): number
	nextLayout += 1
	return nextLayout
end

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
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = item
end

function Ui.stroke(item: GuiObject, color: Color3, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = item
	return stroke
end

-- The thick dark outline around bright text, so it reads on any color.
function Ui.ink(label: TextLabel | TextButton, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Ui.colors.ink
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
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

-- Lays children out in a grid of fixed-size cells.
function Ui.grid(item: GuiObject, cell: UDim2, gap: number)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = cell
	layout.CellPadding = UDim2.fromOffset(gap, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
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

-- A bright button with outlined Fredoka text. kind: claim, primary, social, status, close,
-- secondary or disabled (says what is missing). 48 px tall so it works with a thumb.
function Ui.button(parent: Instance, text: string, kind: string, onClick: (() -> ())?): TextButton
	local fill = buttonColors[kind] or buttonColors.secondary
	local button = Instance.new("TextButton")
	button.AutoButtonColor = kind ~= "disabled"
	button.Size = UDim2.fromOffset(math.max(140, #text * 11 + 48), 48)
	button.BackgroundColor3 = fill
	button.BorderSizePixel = 0
	button.Text = ""
	button.LayoutOrder = nextOrder()
	Ui.corner(button)
	if kind ~= "disabled" then
		Ui.stroke(button, fill:Lerp(Color3.new(1, 1, 1), 0.5), 2)
	end
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Ui.fonts.button
	label.TextSize = 20
	label.Text = text
	label.TextColor3 = if kind == "disabled" then Ui.colors.disabledText else Ui.colors.text
	label.Parent = button
	if kind ~= "disabled" then
		Ui.ink(label)
	end
	if onClick and kind ~= "disabled" then
		button.Activated:Connect(onClick)
	end
	button.Parent = parent
	return button
end

-- The red square X that closes every panel.
function Ui.closeButton(parent: Instance, onClose: () -> ()): TextButton
	local close = Ui.button(parent, "X", "close", onClose)
	close.Name = "Close"
	close.Size = UDim2.fromOffset(48, 48)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	local label = close:FindFirstChild("Label") :: TextLabel
	label.TextSize = 24
	return close
end

-- "ThornjawScale" -> "Thornjaw Scale"
function Ui.pretty(id: string): string
	return (string.gsub(id, "(%l)(%u)", "%1 %2"))
end

-- 1250 -> "1,250"
function Ui.number(n: number): string
	local s = tostring(math.floor(n))
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	return (string.gsub(out, "^,", ""))
end

function Ui.clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Only one panel is open at a time: opening one closes the last.
local current: { root: Frame, onClosed: (() -> ())? }? = nil
function Ui.closeOpen()
	local open = current
	current = nil
	if open then
		open.root:Destroy()
		if open.onClosed then
			open.onClosed()
		end
	end
end
function Ui.isOpen(root: GuiObject): boolean
	return current ~= nil and current.root == root
end

export type Modal = { root: Frame, body: Frame, header: Frame }

-- The panel frame: big caps title, grey line under it, red X top-right, a glowing border in
-- the screen's color. body fills the rest. Covers the middle of the screen.
function Ui.modal(
	gui: ScreenGui,
	title: string,
	subtitle: string,
	accent: Color3,
	onClosed: (() -> ())?,
	maxSize: Vector2?
): Modal
	Ui.closeOpen()
	local root = Ui.frame(gui, UDim2.fromScale(0.82, 0.82), Ui.colors.panel)
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.BackgroundTransparency = 0.04
	-- Above the tiles, wallet and party card on the same screen.
	root.ZIndex = 10
	Ui.corner(root, 16)
	Ui.stroke(root, accent, 3)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = maxSize or Vector2.new(980, 600)
	limit.Parent = root
	Ui.padding(root, 22)

	local header = Ui.frame(root, UDim2.new(1, 0, 0, 56))
	local name = Ui.text(header, string.upper(title), 26, Ui.colors.text, Ui.fonts.heading, 30)
	name.Name = "Title"
	name.AutomaticSize = Enum.AutomaticSize.None
	name.Size = UDim2.new(1, -60, 0, 30)
	local sub = Ui.text(header, subtitle, 14, Ui.colors.muted, Ui.fonts.bold, 18)
	sub.Name = "Subtitle"
	sub.AutomaticSize = Enum.AutomaticSize.None
	sub.Position = UDim2.fromOffset(0, 32)
	sub.Size = UDim2.new(1, -60, 0, 18)
	Ui.closeButton(header, Ui.closeOpen)

	local body = Ui.frame(root, UDim2.new(1, 0, 1, -68))
	body.Position = UDim2.fromOffset(0, 68)
	current = { root = root, onClosed = onClosed }
	return { root = root, body = body, header = header }
end

export type Panel = {
	root: Frame,
	list: ScrollingFrame,
	detail: Frame,
	header: Frame,
}

-- A modal split into a scrolling list on the left and a details box on the right.
function Ui.panel(
	gui: ScreenGui,
	subtitle: string,
	title: string,
	accent: Color3,
	onClosed: (() -> ())?
): Panel
	local modal = Ui.modal(gui, title, subtitle, accent, onClosed)
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(0.48, -8, 1, 0)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Ui.colors.tab
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	Ui.stack(list, 10)
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 2)
	pad.Parent = list
	list.Parent = modal.body

	local detail = Ui.frame(modal.body, UDim2.new(0.52, -8, 1, 0), Ui.colors.inset)
	detail.Position = UDim2.new(0.48, 8, 0, 0)
	Ui.corner(detail, 12)
	Ui.stroke(detail, Ui.colors.line, 2)
	Ui.padding(detail, 18)
	return { root = modal.root, list = list, detail = detail, header = modal.header }
end

-- A row of tabs; the picked one is orange. onPick gets the tab's index.
function Ui.tabs(parent: Instance, names: { string }, picked: number, onPick: (number) -> ()): Frame
	local row = Ui.frame(parent, UDim2.new(1, 0, 0, 46))
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / #names, -8, 1, 0)
	layout.CellPadding = UDim2.fromOffset(10, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	for i, name in names do
		local on = i == picked
		local tab = Instance.new("TextButton")
		tab.LayoutOrder = i
		tab.Text = ""
		tab.BackgroundColor3 = if on then Ui.colors.tab else Ui.colors.night
		tab.BorderSizePixel = 0
		Ui.corner(tab)
		Ui.stroke(tab, if on then Color3.fromRGB(255, 176, 138) else Ui.colors.line, 2)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = if on then Ui.fonts.button else Ui.fonts.bold
		label.TextSize = if on then 18 else 16
		label.TextColor3 = Ui.colors.text
		label.Text = name
		label.Parent = tab
		if on then
			Ui.ink(label)
		end
		tab.Activated:Connect(function()
			onPick(i)
		end)
		tab.Parent = row
	end
	return row
end

-- A row in a panel's list: a colored strip with a label (and a right-hand tag), then a bold
-- name and a grey line under it. The selected row gets a white border.
function Ui.listItem(
	parent: Instance,
	title: string,
	subtitle: string,
	tag: string?,
	tagColor: Color3?,
	selected: boolean,
	onClick: () -> (),
	strip: string?,
	stripColor: Color3?
): TextButton
	local row = Instance.new("TextButton")
	row.AutoButtonColor = true
	row.Text = ""
	row.Size = UDim2.new(1, 0, 0, if strip then 92 else 64)
	row.LayoutOrder = nextOrder()
	row.BackgroundColor3 = Ui.colors.raised
	row.BorderSizePixel = 0
	Ui.corner(row, 10)
	Ui.stroke(row, if selected then Ui.colors.text else Ui.colors.line, 2)
	local top = 10
	if strip then
		local band = Ui.frame(row, UDim2.new(1, 0, 0, 30), stripColor or Ui.colors.blue)
		Ui.corner(band, 10)
		-- Square off the band's bottom corners so it sits flush on the row.
		local flat = Ui.frame(band, UDim2.new(1, 0, 0, 10), stripColor or Ui.colors.blue)
		flat.Position = UDim2.new(0, 0, 1, -10)
		local label = Ui.text(band, strip, 16, Ui.colors.text, Ui.fonts.button, 30)
		label.AutomaticSize = Enum.AutomaticSize.None
		label.Position = UDim2.fromOffset(12, 0)
		label.Size = UDim2.new(1, -24, 1, 0)
		label.ZIndex = 2
		Ui.ink(label)
		top = 38
	end
	local name = Ui.text(row, title, 16, Ui.colors.text, Ui.fonts.bold, 20)
	name.AutomaticSize = Enum.AutomaticSize.None
	name.Position = UDim2.fromOffset(12, top)
	name.Size = UDim2.new(1, -110, 0, 20)
	local sub = Ui.text(row, subtitle, 12, Ui.colors.muted, Ui.fonts.bold, 18)
	sub.AutomaticSize = Enum.AutomaticSize.None
	sub.Position = UDim2.fromOffset(12, top + 22)
	sub.Size = UDim2.new(1, -24, 0, 18)
	if tag then
		local tagLabel = Ui.text(row, tag, 13, tagColor or Ui.colors.muted, Ui.fonts.heading, 20)
		tagLabel.AutomaticSize = Enum.AutomaticSize.None
		tagLabel.Size = UDim2.new(0, 96, 0, 20)
		tagLabel.AnchorPoint = Vector2.new(1, 0)
		tagLabel.Position = UDim2.new(1, -12, 0, if strip then 5 else top)
		tagLabel.TextXAlignment = Enum.TextXAlignment.Right
		tagLabel.ZIndex = 3
		if strip then
			tagLabel.TextColor3 = tagColor or Ui.colors.gold
			Ui.ink(tagLabel)
		end
	end
	row.Activated:Connect(onClick)
	row.Parent = parent
	return row
end

-- A "name ... have / need" line, green when there is enough.
function Ui.costRow(parent: Instance, name: string, have: number, need: number): Frame
	local row = Ui.frame(parent, UDim2.new(1, 0, 0, 42), Ui.colors.raised)
	Ui.corner(row)
	Ui.stroke(row, Ui.colors.line, 2)
	Ui.padding(row, 10)
	local left = Ui.text(row, name, 15, Ui.colors.text, Ui.fonts.bold, 22)
	left.AutomaticSize = Enum.AutomaticSize.None
	local count = Ui.text(
		row,
		`{Ui.number(have)} / {Ui.number(need)}`,
		15,
		if have >= need then Ui.colors.good else Ui.colors.bad,
		Ui.fonts.heading,
		22
	)
	count.AutomaticSize = Enum.AutomaticSize.None
	count.TextXAlignment = Enum.TextXAlignment.Right
	return row
end

-- A menu tile: a dark tint of its color, a light border, a big glyph (or an uploaded icon
-- image) and the name in a solid color strip. badge() shows or hides the red "!".
export type Tile = { button: TextButton, badge: (boolean) -> () }
function Ui.tile(
	parent: Instance,
	name: string,
	color: Color3,
	glyph: string,
	icon: string?,
	onClick: () -> ()
): Tile
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = true
	button.LayoutOrder = nextOrder()
	button.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.72)
	button.BorderSizePixel = 0
	Ui.corner(button, 10)
	Ui.stroke(button, color:Lerp(Color3.new(1, 1, 1), 0.55), 3)
	if icon and icon ~= "" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.AnchorPoint = Vector2.new(0.5, 0)
		image.Position = UDim2.new(0.5, 0, 0, 10)
		image.Size = UDim2.new(0.55, 0, 0.55, 0)
		image.SizeConstraint = Enum.SizeConstraint.RelativeXX
		image.Image = icon
		image.Parent = button
	else
		local mark = Instance.new("TextLabel")
		mark.BackgroundTransparency = 1
		mark.Size = UDim2.new(1, 0, 1, -26)
		mark.Font = Ui.fonts.button
		mark.TextScaled = true
		mark.Text = glyph
		mark.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.6)
		mark.Parent = button
		local fit = Instance.new("UIPadding")
		fit.PaddingTop = UDim.new(0, 12)
		fit.PaddingBottom = UDim.new(0, 4)
		fit.Parent = mark
	end
	local band = Ui.frame(button, UDim2.new(1, 0, 0, 24), color)
	band.AnchorPoint = Vector2.new(0, 1)
	band.Position = UDim2.fromScale(0, 1)
	Ui.corner(band, 8)
	local flat = Ui.frame(band, UDim2.new(1, 0, 0, 8), color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Ui.fonts.button
	label.TextSize = 14
	label.TextColor3 = Ui.colors.text
	label.Text = name
	label.ZIndex = 2
	label.Parent = band
	Ui.ink(label)
	flat.Position = UDim2.fromOffset(0, 0)

	local dot = Instance.new("TextLabel")
	dot.Name = "Badge"
	dot.Visible = false
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -2, 0, 2)
	dot.Size = UDim2.fromOffset(22, 22)
	dot.BackgroundColor3 = Ui.colors.red
	dot.Font = Ui.fonts.heading
	dot.TextSize = 13
	dot.TextColor3 = Ui.colors.text
	dot.Text = "!"
	dot.ZIndex = 5
	Ui.corner(dot, 11)
	Ui.stroke(dot, Ui.colors.text, 2)
	dot.Parent = button

	button.Activated:Connect(onClick)
	button.Parent = parent
	return {
		button = button,
		badge = function(on: boolean)
			dot.Visible = on
		end,
	}
end

-- A currency pill: a colored coin, the amount and a round + button in the same color.
-- Returns the label to update.
function Ui.pill(parent: Instance, color: Color3, onPlus: (() -> ())?): TextLabel
	local pill = Ui.frame(parent, UDim2.new(0.5, -4, 0, 40), Ui.colors.night)
	pill.BackgroundTransparency = 0.1
	Ui.corner(pill, 20)
	Ui.stroke(pill, Color3.fromRGB(43, 46, 58), 2)
	local coin = Ui.frame(pill, UDim2.fromOffset(22, 22), color)
	coin.Position = UDim2.new(0, 10, 0.5, -11)
	Ui.corner(coin, 11)
	Ui.stroke(coin, color:Lerp(Color3.new(1, 1, 1), 0.5), 2)
	local amount = Ui.text(pill, "0", 16, Ui.colors.text, Ui.fonts.heading, 40)
	amount.AutomaticSize = Enum.AutomaticSize.None
	amount.Size = UDim2.new(1, -80, 1, 0)
	amount.Position = UDim2.fromOffset(38, 0)
	amount.TextXAlignment = Enum.TextXAlignment.Right
	local plus = Instance.new("TextButton")
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.Position = UDim2.new(1, -5, 0.5, 0)
	plus.Size = UDim2.fromOffset(30, 30)
	plus.BackgroundColor3 = color
	plus.Font = Ui.fonts.heading
	plus.TextSize = 18
	plus.TextColor3 = Ui.colors.text
	plus.Text = "+"
	Ui.corner(plus, 15)
	plus.Parent = pill
	if onPlus then
		plus.Activated:Connect(onPlus)
	end
	return amount
end

return Ui
