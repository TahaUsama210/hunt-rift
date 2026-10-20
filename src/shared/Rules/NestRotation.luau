--!strict
-- Which monster's egg the nest raid features, and how long until it opens or closes.
-- Pure: the caller passes the schedule from Config/Hub and the time (server Unix time).

local NestRotation = {}

export type Schedule = {
	epoch: number,
	periodSeconds: number,
	raidSeconds: number,
	eggs: { string },
}

export type State = {
	open: boolean, -- a raid is running now
	egg: string, -- the egg being raided if open, else the next egg
	secondsLeft: number, -- until the raid closes if open, else until it opens
}

function NestRotation.at(schedule: Schedule, now: number): State
	local elapsed = now - schedule.epoch
	local cycle = math.floor(elapsed / schedule.periodSeconds)
	local intoCycle = elapsed - cycle * schedule.periodSeconds
	local count = #schedule.eggs
	local function eggAt(index: number): string
		return schedule.eggs[(index % count) + 1]
	end
	if intoCycle < schedule.raidSeconds then
		return { open = true, egg = eggAt(cycle), secondsLeft = schedule.raidSeconds - intoCycle }
	end
	return {
		open = false,
		egg = eggAt(cycle + 1),
		secondsLeft = schedule.periodSeconds - intoCycle,
	}
end

-- "2d 04h 12m", "3h 05m" or "4m 09s" for the countdown sign.
function NestRotation.format(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local days = s // 86400
	local hours = (s % 86400) // 3600
	local minutes = (s % 3600) // 60
	if days > 0 then
		return string.format("%dd %02dh %02dm", days, hours, minutes)
	elseif hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm %02ds", minutes, s % 60)
end

return NestRotation
