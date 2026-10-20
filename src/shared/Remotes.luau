--!strict
-- Every message between client and server is named here and nowhere else.
-- The server creates them on start; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

Remotes.Events = {
	-- client -> server: { weaponId, moveName } when a swing starts
	SwingStarted = "SwingStarted",
	-- server -> client: { player, weaponId, moveName } so others see the swing
	PlayerSwung = "PlayerSwung",
	-- client -> server: { weaponId, moveName, monsterId, part }
	AttackHit = "AttackHit",
	-- server -> client: { monsterId, action } an attack, "flinch" or "death" starting
	MonsterAction = "MonsterAction",
	-- server -> client: { monsterId, part, total, crit, hpLeft }
	DamageDealt = "DamageDealt",
	-- server -> client: { monsterId, part }
	PartBroken = "PartBroken",
	-- server -> client: { monsterId, rewards }
	HuntComplete = "HuntComplete",
	-- client -> server: { recipeId }
	CraftRequest = "CraftRequest",
	-- server -> client: { recipeId, ok, missing }
	CraftResult = "CraftResult",
}

local FOLDER_NAME = "Remotes"

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

-- Call once from the server before any client needs the remotes.
function Remotes.setup()
	local folder = getFolder()
	for _, name in Remotes.Events do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Remotes.get(name: string): RemoteEvent
	assert(Remotes.Events[name], `unknown remote {name}; add it to Remotes.Events`)
	return getFolder():WaitForChild(name) :: RemoteEvent
end

return Remotes
