--!strict
-- Player weapon swings: when a swing may start and when its hit counts.
-- `timing` is a swings entry from Config/Weapons; `grace` is the lag allowance in seconds.

local Swing = {}

export type State = {
	move: string,
	hitFrom: number,
	hitUntil: number,
	busyUntil: number,
	hasHit: boolean,
}

function Swing.start(timing: any, move: string, now: number): State
	local hitFrom = now + timing.windup
	local hitUntil = hitFrom + timing.active
	return {
		move = move,
		hitFrom = hitFrom,
		hitUntil = hitUntil,
		busyUntil = hitUntil + timing.recovery,
		hasHit = false,
	}
end

function Swing.canStart(state: State?, now: number, grace: number): boolean
	return state == nil or now >= state.busyUntil - grace
end

-- One hit per swing, only for the move being swung, only while the blade is moving.
function Swing.canHit(state: State?, move: string, now: number, grace: number): boolean
	if state == nil or state.hasHit or state.move ~= move then
		return false
	end
	return now >= state.hitFrom - grace and now <= state.hitUntil + grace
end

return Swing
