--!strict
-- On-screen bars and messages: your health, the monster's health, the controls, damage
-- numbers and short announcements.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local toastLabel: TextLabel
local hurtFlash: Frame

local function bar(
	name: string,
	position: UDim2,
	anchor: Vector2,
	width: number,
	fill: Color3
): (Frame, TextLabel)
	local back = Instance.new("Frame")
	back.Name = name
	back.AnchorPoint = anchor
	back.Position = position
	back.Size = UDim2.fromOffset(width, 22)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BackgroundTransparency = 0.25
	back.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = back
	local inner = Instance.new("Frame")
	inner.Name = "Fill"
	inner.Size = UDim2.fromScale(1, 1)
	inner.BackgroundColor3 = fill
	inner.BorderSizePixel = 0
	inner.Parent = back
	corner:Clone().Parent = inner
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Parent = back
	back.Parent = gui
	return inner, label
end

local function setFill(fill: Frame, label: TextLabel, text: string, hp: number, maxHp: number)
	fill.Size = UDim2.fromScale(math.clamp(hp / math.max(maxHp, 1), 0, 1), 1)
	label.Text = `{text}  {math.ceil(hp)} / {maxHp}`
end

local function watchPlayer(fill: Frame, label: TextLabel)
	local lastHealth = math.huge
	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		lastHealth = humanoid.Health
		local function update()
			setFill(fill, label, "HP", humanoid.Health, humanoid.MaxHealth)
			if humanoid.Health < lastHealth - 0.5 then
				hurtFlash.BackgroundTransparency = 0.6
				TweenService:Create(hurtFlash, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
					:Play()
			end
			lastHealth = humanoid.Health
		end
		humanoid.HealthChanged:Connect(update)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

-- Shows the closest living monster's health at the top of the screen.
local function watchMonsters(fill: Frame, label: TextLabel)
	local frame = fill.Parent :: Frame
	RunService.RenderStepped:Connect(function()
		local folder = Workspace:FindFirstChild("Monsters")
		local camera = Workspace.CurrentCamera
		local best, bestDist = nil, math.huge
		if folder and camera then
			for _, model in folder:GetChildren() do
				local hp = model:GetAttribute("Hp")
				local root = model:FindFirstChild("Root")
				if typeof(hp) == "number" and hp > 0 and root and root:IsA("BasePart") then
					local d = (root.Position - camera.CFrame.Position).Magnitude
					if d < bestDist then
						best, bestDist = model, d
					end
				end
			end
		end
		-- No monster bar while you are in camp, high above the hunting ground.
		if player:GetAttribute("Location") == "Camp" then
			best = nil
		end
		frame.Visible = best ~= nil
		if best then
			local monster = Monsters[best:GetAttribute("MonsterId")]
			local name = if monster then monster.displayName else best.Name
			setFill(
				fill,
				label,
				name,
				best:GetAttribute("Hp") :: number,
				best:GetAttribute("MaxHp") :: number
			)
		end
	end)
end

function Hud.toast(text: string, seconds: number?)
	toastLabel.Text = text
	toastLabel.TextTransparency = 0
	toastLabel.TextStrokeTransparency = 0.4
	local shown = text
	task.delay(seconds or 3, function()
		if toastLabel.Text == shown then
			local fade = TweenInfo.new(0.6)
			TweenService
				:Create(toastLabel, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
		end
	end)
end

-- A number that floats up from where the hit landed.
function Hud.damageNumber(position: Vector3, amount: number, crit: string)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position + Vector3.new(math.random() - 0.5, 1, math.random() - 0.5)
	anchor.Parent = Workspace.CurrentCamera
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(120, 50)
	board.AlwaysOnTop = true
	board.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = tostring(amount)
	label.TextColor3 = if crit == "crit"
		then Color3.fromRGB(255, 210, 60)
		elseif crit == "weak" then Color3.fromRGB(170, 170, 170)
		else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = board
	local rise = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, rise, { Position = anchor.Position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, rise, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		anchor:Destroy()
	end)
end

function Hud.start(controls: { string })
	gui = Instance.new("ScreenGui")
	gui.Name = "HuntHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	hurtFlash = Instance.new("Frame")
	hurtFlash.Size = UDim2.fromScale(1, 1)
	hurtFlash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	hurtFlash.BackgroundTransparency = 1
	hurtFlash.BorderSizePixel = 0
	hurtFlash.Parent = gui

	-- Top-left, under Roblox's own buttons: the bottom-left belongs to the camp wallet.
	local playerFill, playerLabel = bar(
		"PlayerHealth",
		UDim2.new(0, 20, 0, 66),
		Vector2.new(0, 0),
		280,
		Color3.fromRGB(70, 190, 90)
	)
	watchPlayer(playerFill, playerLabel)

	local monsterFill, monsterLabel = bar(
		"MonsterHealth",
		UDim2.new(0.5, 0, 0, 60),
		Vector2.new(0.5, 0),
		460,
		Color3.fromRGB(200, 60, 50)
	)
	watchMonsters(monsterFill, monsterLabel)

	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -20, 1, -20)
	hint.Size = UDim2.fromOffset(260, 70)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 14
	hint.TextColor3 = Color3.new(1, 1, 1)
	hint.TextStrokeTransparency = 0.5
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.TextYAlignment = Enum.TextYAlignment.Bottom
	hint.Text = table.concat(controls, "\n")
	hint.Parent = gui

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)
	toastLabel.Position = UDim2.new(0.5, 0, 0, 100)
	toastLabel.Size = UDim2.fromOffset(600, 40)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Font = Enum.Font.GothamBlack
	toastLabel.TextSize = 26
	toastLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	toastLabel.TextTransparency = 1
	toastLabel.TextStrokeTransparency = 1
	toastLabel.Parent = gui

	-- Your health and the controls are for the hunt; camp has its own screen (CampHud).
	local playerBar = playerFill.Parent :: Frame
	local function showFor()
		local inCamp = player:GetAttribute("Location") == "Camp"
		playerBar.Visible = not inCamp
		hint.Visible = not inCamp
	end
	player:GetAttributeChangedSignal("Location"):Connect(showFor)
	showFor()
end

return Hud
