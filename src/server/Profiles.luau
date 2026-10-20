--!strict
-- Each player's saved profile: gold, Rift Shards, carved items and the daily reward streak.
-- Saved in a DataStore on leave and on shutdown. In Studio this needs Game Settings > Security >
-- "Enable Studio Access to API Services"; without it the game still runs with a fresh profile
-- that is not saved, and the Output says so once.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Profiles = {}

export type Profile = {
	items: { [string]: number },
	gold: number,
	shards: number,
	daily: { streak: number, lastDay: number? },
}

local STORE_NAME = "HuntRiftProfiles_v1"
local STARTING_GOLD = 500

local profiles: { [Player]: Profile } = {}
local loaded: { [Player]: boolean } = {}
local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`Profiles are not saved this session (no DataStore access): {result}`)
	end
end

local function fresh(): Profile
	return { items = {}, gold = STARTING_GOLD, shards = 0, daily = { streak = 0, lastDay = nil } }
end

-- Fills in anything an older save is missing, so new fields never break old profiles.
local function upgrade(saved: any): Profile
	local profile = fresh()
	if typeof(saved) ~= "table" then
		return profile
	end
	if typeof(saved.items) == "table" then
		profile.items = saved.items
	end
	if typeof(saved.gold) == "number" then
		profile.gold = saved.gold
	end
	if typeof(saved.shards) == "number" then
		profile.shards = saved.shards
	end
	if typeof(saved.daily) == "table" and typeof(saved.daily.streak) == "number" then
		profile.daily = { streak = saved.daily.streak, lastDay = saved.daily.lastDay }
	end
	return profile
end

local function key(player: Player): string
	return `player_{player.UserId}`
end

local function save(player: Player)
	local profile = profiles[player]
	-- Never save over real data with a profile that failed to load.
	if not (store and profile and loaded[player]) then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(key(player), profile)
	end)
	if not ok then
		warn(`Could not save {player.Name}'s profile: {err}`)
	end
end

-- Loads a joining player's profile (yields). Always returns one, fresh if the load fails.
local function load(player: Player): Profile
	if not store then
		return fresh()
	end
	local ok, saved = pcall(function()
		return (store :: DataStore):GetAsync(key(player))
	end)
	if not ok then
		warn(
			`Could not load {player.Name}'s profile, using a fresh one that will not save: {saved}`
		)
		return fresh()
	end
	loaded[player] = true
	return upgrade(saved)
end

-- The player's profile, or nil while it is still loading.
function Profiles.get(player: Player): Profile?
	return profiles[player]
end

-- Calls back once the profile is ready (right away if it already is).
local waiting: { [Player]: { (Profile) -> () } } = {}
function Profiles.whenReady(player: Player, callback: (Profile) -> ())
	local profile = profiles[player]
	if profile then
		callback(profile)
		return
	end
	waiting[player] = waiting[player] or {}
	table.insert(waiting[player], callback)
end

function Profiles.start()
	local function onPlayer(player: Player)
		local profile = load(player)
		if player.Parent ~= Players then
			-- Left while loading: nothing changed, so there is nothing to save.
			loaded[player] = nil
			return
		end
		profiles[player] = profile
		local queued = waiting[player]
		if queued then
			for _, callback in queued do
				task.spawn(callback, profile)
			end
		end
		waiting[player] = nil
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		loaded[player] = nil
		waiting[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)
end

return Profiles
