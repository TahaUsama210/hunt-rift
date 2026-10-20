--!strict
-- Daily login streak. Pure: the server passes the saved state and the time (Unix seconds).
-- Days are UTC calendar days, so everyone's reward resets at the same moment.

local DailyRewards = {}

export type State = {
	streak: number, -- days claimed in a row, 0 if never
	lastDay: number?, -- UTC day number of the last claim
}

export type Status = {
	day: number, -- which calendar day (1 to dayCount) is up next or was just claimed
	canClaim: boolean,
	secondsUntilNext: number, -- until a new claim opens (0 when one is open now)
}

local DAY = 86400

local function dayOf(now: number): number
	return math.floor(now / DAY)
end

-- Whether the streak carries on today (claimed yesterday) or has to start again.
local function continues(state: State, today: number): boolean
	return state.lastDay ~= nil and today - state.lastDay <= 1 and state.streak > 0
end

function DailyRewards.status(state: State, now: number, dayCount: number): Status
	local today = dayOf(now)
	if state.lastDay == today then
		-- Already claimed today: show today's day as done, the next opens at midnight UTC.
		local shown = ((state.streak - 1) % dayCount) + 1
		return { day = shown, canClaim = false, secondsUntilNext = (today + 1) * DAY - now }
	end
	local nextDay = if continues(state, today) then (state.streak % dayCount) + 1 else 1
	return { day = nextDay, canClaim = true, secondsUntilNext = 0 }
end

-- Returns the new state and which calendar day was claimed, or nil if nothing can be claimed.
function DailyRewards.claim(state: State, now: number, dayCount: number): (State?, number?)
	local status = DailyRewards.status(state, now, dayCount)
	if not status.canClaim then
		return nil, nil
	end
	local today = dayOf(now)
	local streak = if continues(state, today) then state.streak + 1 else 1
	return { streak = streak, lastDay = today }, status.day
end

return DailyRewards
