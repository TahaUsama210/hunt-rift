local T = require("./TestKit")
local DailyRewards = require("../src/shared/Rules/DailyRewards")
local Config = require("../src/shared/Config/DailyRewards")

local DAY = 86400
local fresh = { streak = 0, lastDay = nil }

T.test("a new hunter can claim day 1", function()
	local s = DailyRewards.status(fresh, 10 * DAY + 5, 7)
	T.equal(s.canClaim, true)
	T.equal(s.day, 1)
end)

T.test("claiming twice in one day is refused until midnight", function()
	local state, day = DailyRewards.claim(fresh, 10 * DAY + 100, 7)
	assert(state, "first claim works")
	T.equal(day, 1)
	local again = DailyRewards.claim(state, 10 * DAY + 200, 7)
	T.equal(again, nil)
	local s = DailyRewards.status(state, 10 * DAY + 200, 7)
	T.equal(s.canClaim, false)
	T.equal(s.day, 1)
	T.equal(s.secondsUntilNext, DAY - 200)
end)

T.test("coming back the next day moves the streak on", function()
	local state = DailyRewards.claim(fresh, 10 * DAY, 7)
	local next, day = DailyRewards.claim(state :: any, 11 * DAY + 50000, 7)
	T.equal(day, 2)
	T.equal((next :: any).streak, 2)
end)

T.test("missing a day starts again at day 1", function()
	local state = { streak = 4, lastDay = 10 }
	local s = DailyRewards.status(state, 12 * DAY, 7)
	T.equal(s.day, 1)
	local next = DailyRewards.claim(state, 12 * DAY, 7)
	T.equal((next :: any).streak, 1)
end)

T.test("after day 7 the week starts over", function()
	local state = { streak = 7, lastDay = 10 }
	T.equal(DailyRewards.status(state, 11 * DAY, 7).day, 1)
	local next, day = DailyRewards.claim(state, 11 * DAY, 7)
	T.equal(day, 1)
	T.equal((next :: any).streak, 8)
	T.equal(DailyRewards.status(next :: any, 11 * DAY, 7).day, 1, "claimed day 1 of week 2")
end)

T.test("every calendar day pays something", function()
	T.equal(#Config.days, 7)
	for i, reward in Config.days do
		assert(reward.gold > 0 or reward.shards > 0, `day {i} pays nothing`)
	end
end)
