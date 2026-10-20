--!strict
-- The UI kit: colors, fonts and the building blocks every menu uses, so all screens share one
-- chunky look (see the UI kit board on the Hunt Rift hub and UI design canvas): near-black
-- panels with a glowing colored border, white caps titles, a red X, bright buttons with
-- outlined text, menu tiles with a colored name strip, and currency pills.
-- Everything you can press is springy (grows under the mouse, squishes when pressed, bounces
-- back), panels pop in, and only things that want a tap pulse or shine (research/vfx.md).
-- With the player's Reduce Motion setting on, tweens finish at once and nothing loops.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

-- The player's Reduce Motion setting.
function Ui.reducedMotion(): boolean
	return GuiService.ReducedMotionEnabled
end

function Ui.tween(
	item: Instance,
	seconds: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		item,
		TweenInfo.new(
			if Ui.reducedMotion() then 0 else seconds,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		props
	)
	tween:Play()
	return tween
end

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Every looping animation (pulses, shimmering borders, shines) runs off one Heartbeat.
type Loop = { item: Instance, step: (now: number) -> () }
local loops: { Loop } = {}
local looping = false
local function loop(item: Instance, step: (now: number) -> ())
	table.insert(loops, { item = item, step = step })
	if looping then
		return
	end
	looping = true
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local still = Ui.reducedMotion()
		for i = #loops, 1, -1 do
			local entry = loops[i]
			if entry.item.Parent == nil then
				table.remove(loops, i)
			elseif not still then
				entry.step(now)
			end
		end
	end)
end

-- Makes something pressable springy. `holder` is what grows and shrinks (it must be centered:
-- AnchorPoint 0.5, 0.5); `face` dips onto its lip while pressed. A press answers at once (a
-- quick squish), the release bounces back past where it was.
local function spring(button: GuiButton, holder: GuiObject, face: GuiObject?, hover: number?)
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	local over, down = false, false
	local function settle()
		if down then
			Ui.tween(scale, 0.08, { Scale = 0.95 })
		else
			Ui.tween(
				scale,
				0.22,
				{ Scale = if over then hover or 1.05 else 1 },
				Enum.EasingStyle.Back
			)
		end
		if face then
			Ui.tween(face, 0.08, { Position = UDim2.fromOffset(0, if down then 3 else 0) })
		end
	end
	button.MouseEnter:Connect(function()
		over = true
		settle()
	end)
	button.MouseLeave:Connect(function()
		over = false
		down = false
		settle()
	end)
	button.InputBegan:Connect(function(input)
		if isPress(input) then
			down = true
			settle()
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			down = false
			settle()
		end
	end)
end
Ui.spring = spring

-- A slow breathing pulse (for things that want a tap: a Claim button, a badge).
function Ui.pulse(item: GuiObject, amount: number?, speed: number?)
	local scale = item:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = item
	local phase = math.random() * 3
	loop(item, function(now)
		scale.Scale = 1 + (amount or 0.05) * (0.5 + 0.5 * math.sin((now + phase) * (speed or 4)))
	end)
end

-- A bright band that runs around a border (UIStroke) for things that are ready to claim.
function Ui.shimmer(stroke: UIStroke, color: Color3)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.45, color),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, color),
	})
	gradient.Parent = stroke
	loop(stroke, function(now)
		gradient.Rotation = (now * 120) % 360
	end)
end

-- Every few seconds a soft white band sweeps across `face` (it must clip its descendants).
-- Only for things with something to collect; hide the returned band when there is nothing.
function Ui.shine(face: GuiObject, every: number?): Frame
	local band = Instance.new("Frame")
	band.Name = "Shine"
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Size = UDim2.new(0.35, 0, 2, 0)
	band.Rotation = 20
	band.BackgroundColor3 = Color3.new(1, 1, 1)
	band.BorderSizePixel = 0
	band.ZIndex = 4
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = band
	band.Position = UDim2.fromScale(-0.6, 0.5)
	band.Parent = face
	local period = every or 5
	local offset = math.random() * period
	loop(band, function(now)
		local k = ((now + offset) % period) / 0.7
		band.Position = UDim2.fromScale(if k < 1 then -0.6 + 2.2 * k else -0.6, 0.5)
	end)
	return band
end

-- Little coins (or shards) fly from `from` into the counter registered as `target`, then the
-- counter bounces. Pure show: the server already decided the reward.
local targets: { [string]: GuiObject } = {}
function Ui.target(name: string, item: GuiObject)
	targets[name] = item
end
function Ui.flyTo(gui: ScreenGui, from: GuiObject, target: string, color: Color3, count: number?)
	local goal = targets[target]
	if not goal then
		return
	end
	local inset = gui.AbsolutePosition
	local start = from.AbsolutePosition + from.AbsoluteSize / 2 - inset
	local finish = goal.AbsolutePosition + Vector2.new(22, goal.AbsoluteSize.Y / 2) - inset
	for i = 1, count or 8 do
		local coin = Instance.new("Frame")
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.Size = UDim2.fromOffset(18, 18)
		coin.BackgroundColor3 = color
		coin.ZIndex = 50
		Ui.corner(coin, 9)
		Ui.stroke(coin, color:Lerp(Color3.new(1, 1, 1), 0.6), 2)
		local spread = Vector2.new(math.random(-60, 60), math.random(-70, -10))
		coin.Position = UDim2.fromOffset(start.X, start.Y)
		coin.Parent = gui
		task.delay((i - 1) * 0.04, function()
			local burst = start + spread
			Ui.tween(coin, 0.22, { Position = UDim2.fromOffset(burst.X, burst.Y) })
			task.delay(0.22, function()
				local fly = Ui.tween(coin, 0.45, {
					Position = UDim2.fromOffset(finish.X, finish.Y),
					Size = UDim2.fromOffset(12, 12),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				fly.Completed:Connect(function()
					coin:Destroy()
					Ui.bump(goal)
				end)
			end)
		end)
	end
end

-- A reward pop, the moment players like most (research/vfx.md): sparkles burst out of `from`
-- (the screen's middle when nil) and the reward lines pop up, hang a moment and float off.
-- Pure show, like flyTo.
export type RewardLine = { text: string, color: Color3 }
function Ui.celebrate(gui: ScreenGui, from: GuiObject?, lines: { RewardLine })
	local center = if from
		then from.AbsolutePosition + from.AbsoluteSize / 2 - gui.AbsolutePosition
		else gui.AbsoluteSize / 2
	if not Ui.reducedMotion() then
		local count = 12
		for i = 1, count do
			local angle = (i / count) * math.pi * 2 + math.random() * 0.3
			local star = Instance.new("Frame")
			star.AnchorPoint = Vector2.new(0.5, 0.5)
			star.Size = UDim2.fromOffset(12, 12)
			star.Rotation = 45
			star.BackgroundColor3 = lines[i % #lines + 1].color:Lerp(Color3.new(1, 1, 1), 0.35)
			star.BorderSizePixel = 0
			star.ZIndex = 60
			star.Position = UDim2.fromOffset(center.X, center.Y)
			star.Parent = gui
			local to = center
				+ Vector2.new(math.cos(angle), math.sin(angle)) * (70 + math.random() * 50)
			Ui.tween(star, 0.55, {
				Position = UDim2.fromOffset(to.X, to.Y),
				Size = UDim2.fromOffset(4, 4),
				BackgroundTransparency = 1,
				Rotation = 225,
			}, Enum.EasingStyle.Quart)
			task.delay(0.6, function()
				star:Destroy()
			end)
		end
	end
	local stack = Instance.new("Frame")
	stack.BackgroundTransparency = 1
	stack.AnchorPoint = Vector2.new(0.5, 1)
	stack.Position = UDim2.fromOffset(center.X, center.Y - 16)
	stack.Size = UDim2.fromOffset(360, #lines * 36)
	stack.ZIndex = 61
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 34)
		label.Position = UDim2.fromOffset(0, (i - 1) * 36)
		label.Font = Ui.fonts.button
		label.TextSize = 30
		label.TextColor3 = line.color
		label.Text = line.text
		label.ZIndex = 61
		Ui.ink(label, 3)
		label.Parent = stack
	end
	local pop = Instance.new("UIScale")
	pop.Scale = 0.6
	pop.Parent = stack
	stack.Parent = gui
	Ui.tween(pop, 0.18, { Scale = 1.15 }).Completed:Connect(function()
		Ui.tween(pop, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	task.delay(1.4, function()
		Ui.tween(stack, 0.5, { Position = UDim2.fromOffset(center.X, center.Y - 70) })
		for _, label in stack:GetChildren() do
			if label:IsA("TextLabel") then
				Ui.tween(label, 0.5, { TextTransparency = 1 })
				local stroke = label:FindFirstChildOfClass("UIStroke")
				if stroke then
					Ui.tween(stroke, 0.5, { Transparency = 1 })
				end
			end
		end
		task.delay(0.55, function()
			stack:Destroy()
		end)
	end)
end

-- A quick pop, for a counter that just went up.
function Ui.bump(target: GuiObject)
	local holder = target:FindFirstChild("Holder")
	local item = if holder and holder:IsA("GuiObject") then holder else target
	local scale = item:FindFirstChild("Bump") :: UIScale?
	if not scale then
		local new = Instance.new("UIScale")
		new.Name = "Bump"
		new.Parent = item
		scale = new
	end
	local s = scale :: UIScale
	s.Scale = 1.15
	Ui.tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Shrinks a screen widget on short screens (phones held sideways), so the kit's chunky fixed
-- sizes still fit. It scales around the widget's AnchorPoint, so corner widgets stay put.
local FIT_HEIGHT = 720
function Ui.fit(item: GuiObject)
	local gui = item:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return
	end
	local scale = Instance.new("UIScale")
	scale.Name = "Fit"
	scale.Parent = item
	local function update()
		scale.Scale = math.clamp(gui.AbsoluteSize.Y / FIT_HEIGHT, 0.6, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

-- Phones and tablets: no keyboard, so the thumbstick and jump button own the bottom corners.
function Ui.touchOnly(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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

-- The chunky raised look shared by buttons and tiles: inside the (invisible) button sits a
-- centered holder that springs, a darker lip under it, and the face on top with a glossy
-- gradient and a light top half. Returns the face to put content on.
local function raised(button: TextButton, fill: Color3, radius: number, lift: number): Frame
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = button
	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.Size = UDim2.new(1, 0, 1, 0)
	lip.Position = UDim2.fromOffset(0, lift)
	lip.BackgroundColor3 = fill:Lerp(Color3.new(0, 0, 0), 0.45)
	lip.BorderSizePixel = 0
	Ui.corner(lip, radius)
	lip.Parent = holder
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 1, 0)
	face.BackgroundColor3 = fill
	face.BorderSizePixel = 0
	face.ClipsDescendants = true
	Ui.corner(face, radius)
	local gloss = Instance.new("UIGradient")
	gloss.Rotation = 90
	gloss.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.78, 0.78, 0.78))
	gloss.Parent = face
	local shine = Instance.new("Frame")
	shine.Name = "Gloss"
	shine.Size = UDim2.new(1, -8, 0.45, 0)
	shine.Position = UDim2.fromOffset(4, 3)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	Ui.corner(shine, math.max(2, radius - 3))
	shine.Parent = face
	face.Parent = holder
	spring(button, holder, face)
	return face
end
Ui.raised = raised

-- A bright button with outlined Fredoka text. kind: claim, primary, social, status, close,
-- secondary or disabled (says what is missing). 48 px tall so it works with a thumb. Claim
-- buttons breathe and their border shimmers, because they are good news.
function Ui.button(parent: Instance, text: string, kind: string, onClick: (() -> ())?): TextButton
	local fill = buttonColors[kind] or buttonColors.secondary
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(math.max(140, #text * 11 + 48), 48)
	button.BorderSizePixel = 0
	button.LayoutOrder = nextOrder()
	local face = raised(button, fill, 10, if kind == "disabled" then 0 else 4)
	if kind ~= "disabled" then
		local stroke = Ui.stroke(face, fill:Lerp(Color3.new(1, 1, 1), 0.5), 2)
		if kind == "claim" then
			Ui.shimmer(stroke, fill:Lerp(Color3.new(1, 1, 1), 0.5))
		end
	end
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Ui.fonts.button
	label.TextSize = 20
	label.Text = text
	label.ZIndex = 3
	label.TextColor3 = if kind == "disabled" then Ui.colors.disabledText else Ui.colors.text
	label.Parent = face
	if kind ~= "disabled" then
		Ui.ink(label)
	end
	if kind == "claim" then
		Ui.pulse(label, 0.08, 4)
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
	local label = close:FindFirstChild("Label", true) :: TextLabel
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
local current: { root: Frame, dim: TextButton, onClosed: (() -> ())? }? = nil
function Ui.closeOpen()
	local open = current
	current = nil
	if open then
		open.root:Destroy()
		open.dim:Destroy()
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
	-- The world behind dims while a panel is open; tapping it closes the panel.
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.ZIndex = 9
	dim.Parent = gui
	dim.Activated:Connect(Ui.closeOpen)
	Ui.tween(dim, 0.25, { BackgroundTransparency = 0.55 })
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
	-- Pops in: a little small and see-through, then a springy settle.
	local pop = Instance.new("UIScale")
	pop.Scale = 0.85
	pop.Parent = root
	Ui.tween(pop, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	current = { root = root, dim = dim, onClosed = onClosed }
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

-- An icon from Config/Icons: the uploaded image when there is one, its emoji until then.
export type Icon = { image: string, emoji: string }
function Ui.icon(parent: Instance, icon: Icon): GuiObject
	local art: GuiObject
	if icon.image ~= "" then
		local image = Instance.new("ImageLabel")
		image.Image = icon.image
		image.ScaleType = Enum.ScaleType.Fit
		art = image
	else
		local glyph = Instance.new("TextLabel")
		glyph.Font = Ui.fonts.button
		glyph.TextScaled = true
		glyph.TextColor3 = Ui.colors.text
		glyph.Text = icon.emoji
		art = glyph
	end
	art.Name = "Icon"
	art.BackgroundTransparency = 1
	art.Parent = parent
	return art
end

-- A menu tile: a raised dark tint of its color with a light border, a big icon (Ui.icon) and
-- the name in a solid color strip. The icon pops and tilts under the mouse, and badge() shows or hides the bouncing red
-- "!" and a shine that sweeps across now and then (only while there is something to collect).
export type Tile = { button: TextButton, badge: (boolean) -> () }
function Ui.tile(parent: Instance, name: string, color: Color3, icon: Icon, onClick: () -> ()): Tile
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = nextOrder()
	button.BorderSizePixel = 0
	local face = raised(button, color:Lerp(Color3.new(0, 0, 0), 0.62), 12, 5)
	Ui.stroke(face, color:Lerp(Color3.new(1, 1, 1), 0.55), 3)
	local art = Ui.icon(face, icon)
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.new(0.5, 0, 0.5, -11)
	art.Size = UDim2.new(0.72, 0, 1, -34)
	art.ZIndex = 2
	local pop = Instance.new("UIScale")
	pop.Parent = art
	button.MouseEnter:Connect(function()
		Ui.tween(pop, 0.25, { Scale = 1.14 }, Enum.EasingStyle.Back)
		Ui.tween(art, 0.25, { Rotation = -8 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Ui.tween(pop, 0.2, { Scale = 1 })
		Ui.tween(art, 0.2, { Rotation = 0 })
	end)

	local band = Ui.frame(face, UDim2.new(1, 0, 0, 24), color)
	band.AnchorPoint = Vector2.new(0, 1)
	band.Position = UDim2.fromScale(0, 1)
	band.ZIndex = 3
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Ui.fonts.button
	label.TextSize = 15
	label.TextColor3 = Ui.colors.text
	label.Text = name
	label.ZIndex = 4
	label.Parent = band
	Ui.ink(label)
	local shine = Ui.shine(face, 4 + math.random() * 2)
	shine.Visible = false

	-- The badge sits on the holder, outside the face, so the face's clipping cannot cut it.
	local dot = Instance.new("TextLabel")
	dot.Name = "Badge"
	dot.Visible = false
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -4, 0, 4)
	dot.Size = UDim2.fromOffset(26, 26)
	dot.BackgroundColor3 = Ui.colors.red
	dot.Font = Ui.fonts.button
	dot.TextSize = 17
	dot.TextColor3 = Ui.colors.text
	dot.Text = "!"
	dot.ZIndex = 6
	Ui.corner(dot, 13)
	Ui.stroke(dot, Ui.colors.text, 2)
	dot.Parent = face.Parent
	Ui.pulse(dot, 0.18, 6)
	loop(dot, function(now)
		dot.Rotation = 12 * math.sin(now * 9) * math.max(0, math.sin(now * 1.6))
	end)

	button.Activated:Connect(onClick)
	button.Parent = parent
	return {
		button = button,
		badge = function(on: boolean)
			dot.Visible = on
			shine.Visible = on
		end,
	}
end

-- A currency pill: its icon (a colored coin until the image is uploaded), the amount and a
-- round + button in the same color. Returns the label to update; Ui.count rolls it to a new
-- number. Register the pill with Ui.target so rewards can fly into it.
function Ui.pill(parent: Instance, color: Color3, icon: Icon, onPlus: (() -> ())?): TextLabel
	local pill = Ui.frame(parent, UDim2.new(0.5, -4, 0, 40))
	local holder = Ui.frame(pill, UDim2.fromScale(1, 1), Ui.colors.night)
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.BackgroundTransparency = 0.1
	Ui.corner(holder, 20)
	Ui.stroke(holder, Color3.fromRGB(43, 46, 58), 2)
	local coin = Ui.frame(holder, UDim2.fromOffset(24, 24), color)
	coin.Name = "Coin"
	coin.Position = UDim2.new(0, 9, 0.5, -12)
	Ui.corner(coin, 12)
	Ui.stroke(coin, color:Lerp(Color3.new(1, 1, 1), 0.5), 2)
	local glint = Ui.frame(coin, UDim2.fromOffset(8, 8), Color3.new(1, 1, 1))
	glint.Position = UDim2.fromOffset(4, 4)
	glint.BackgroundTransparency = 0.3
	Ui.corner(glint, 4)
	if icon.image ~= "" then
		-- The rendered coin sits a little bigger than the pill, like a sticker.
		coin.BackgroundTransparency = 1
		glint.Visible = false
		local stroke = coin:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Enabled = false
		end
		local art = Ui.icon(coin, icon)
		art.AnchorPoint = Vector2.new(0.5, 0.5)
		art.Position = UDim2.fromScale(0.5, 0.5)
		art.Size = UDim2.fromOffset(34, 34)
	end
	local amount = Ui.text(holder, "0", 17, Ui.colors.text, Ui.fonts.button, 40)
	amount.AutomaticSize = Enum.AutomaticSize.None
	amount.Size = UDim2.new(1, -80, 1, 0)
	amount.Position = UDim2.fromOffset(38, 0)
	amount.TextXAlignment = Enum.TextXAlignment.Right
	Ui.ink(amount)
	local plus = Instance.new("TextButton")
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.Position = UDim2.new(1, -5, 0.5, 0)
	plus.Size = UDim2.fromOffset(30, 30)
	plus.BackgroundColor3 = color
	plus.Font = Ui.fonts.button
	plus.TextSize = 22
	plus.TextColor3 = Ui.colors.text
	plus.Text = "+"
	Ui.corner(plus, 15)
	Ui.stroke(plus, color:Lerp(Color3.new(1, 1, 1), 0.5), 2)
	plus.Parent = holder
	spring(plus, plus, nil, 1.15)
	if onPlus then
		plus.Activated:Connect(onPlus)
	end
	return amount
end

-- Rolls a number label from what it shows now up (or down) to `value`.
function Ui.count(label: TextLabel, value: number)
	local from = tonumber((string.gsub(label.Text, ",", ""))) or 0
	if from == value then
		label.Text = Ui.number(value)
		return
	end
	local counter = Instance.new("NumberValue")
	counter.Value = from
	counter.Changed:Connect(function(v)
		label.Text = Ui.number(v)
	end)
	local roll = Ui.tween(counter, if value > from then 0.8 else 0.3, { Value = value })
	roll.Completed:Connect(function()
		label.Text = Ui.number(value)
		counter:Destroy()
	end)
end

return Ui
