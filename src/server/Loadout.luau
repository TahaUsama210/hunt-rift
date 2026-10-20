--!strict
-- Gives every character its hunting health and a sword welded into the right hand.
-- The sword is a Model called "Weapon" with a WeaponId attribute the client reads.

local Loadout = {}

local equipped: { [Player]: string } = {}

local function piece(
	class: string,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): BasePart
	local part = Instance.new(class) :: BasePart
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	return part
end

local function attach(part0: BasePart, part1: BasePart, offset: CFrame)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = offset
	weld.Parent = part1
end

-- A broad iron blade pointing forward out of the fist (-Z of the hand).
local function buildSword(weaponId: string): Model
	local model = Instance.new("Model")
	model.Name = "Weapon"
	model:SetAttribute("WeaponId", weaponId)
	local steel = Color3.fromRGB(176, 182, 190)
	local length = 4.6
	local handle = piece(
		"Part",
		"Handle",
		Vector3.new(0.3, 0.3, 1.5),
		Color3.fromRGB(82, 52, 34),
		Enum.Material.Wood
	)
	local guard = piece(
		"Part",
		"Guard",
		Vector3.new(0.5, 1.7, 0.35),
		Color3.fromRGB(60, 62, 70),
		Enum.Material.Metal
	)
	local blade = piece("Part", "Blade", Vector3.new(0.22, 1.2, length), steel, Enum.Material.Metal)
	local tip = piece("WedgePart", "Tip", Vector3.new(0.22, 1.2, 0.9), steel, Enum.Material.Metal)
	for _, p in { handle, guard, blade, tip } do
		p.Parent = model
	end
	model.PrimaryPart = handle
	attach(handle, guard, CFrame.new(0, 0, -0.8))
	attach(handle, blade, CFrame.new(0, 0, -0.95 - length / 2))
	attach(handle, tip, CFrame.new(0, 0, -0.95 - length - 0.45))
	return model
end

local function onCharacter(player: Player, character: Model, maxHp: number)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.MaxHealth = maxHp
	humanoid.Health = maxHp
	local hand = if humanoid.RigType == Enum.HumanoidRigType.R15
		then character:WaitForChild("RightHand", 10)
		else character:WaitForChild("Right Arm", 10)
	if not (hand and hand:IsA("BasePart")) then
		return
	end
	local sword = buildSword(equipped[player])
	sword.Parent = character
	attach(hand, sword.PrimaryPart :: BasePart, CFrame.new(0, -hand.Size.Y / 2, 0))
end

function Loadout.start(hunt: any)
	local function added(player: Player)
		equipped[player] = hunt.startingWeapon
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character, hunt.playerMaxHp)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character, hunt.playerMaxHp)
		end
	end
	game:GetService("Players").PlayerAdded:Connect(added)
	for _, player in game:GetService("Players"):GetPlayers() do
		added(player)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		equipped[player] = nil
	end)
end

function Loadout.weaponOf(player: Player): string?
	return equipped[player]
end

return Loadout
