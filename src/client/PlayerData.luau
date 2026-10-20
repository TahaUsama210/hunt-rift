--!strict
-- What the server last told this client about its own profile: items, gold, Rift Shards and
-- the daily reward calendar. Screens read it and redraw on changed. Display only: the server
-- decides everything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local PlayerData = {}

PlayerData.items = {} :: { [string]: number }
PlayerData.gold = 0
PlayerData.shards = 0
PlayerData.daily = { day = 1, canClaim = false, secondsUntilNext = math.huge, streak = 0, at = 0 }

local event = Instance.new("BindableEvent")
-- Fires after any change from the server.
PlayerData.changed = event.Event

function PlayerData.start()
	Remotes.get("InventoryChanged").OnClientEvent:Connect(function(items, gold, shards)
		PlayerData.items = items
		PlayerData.gold = gold
		PlayerData.shards = shards or 0
		event:Fire()
	end)
	Remotes.get("DailyStatus").OnClientEvent:Connect(function(day, canClaim, seconds, streak)
		PlayerData.daily = {
			day = day,
			canClaim = canClaim,
			secondsUntilNext = seconds,
			streak = streak,
			at = os.clock(),
		}
		event:Fire()
	end)
	Remotes.get("InventoryRequest"):FireServer()
end

return PlayerData
