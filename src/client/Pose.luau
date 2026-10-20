--!strict
-- Small helpers for procedural animation: poses are tables of joint name to
-- { pitch, yaw, roll } in degrees and { x, y, z } in studs, added on top of the rest pose.

local Pose = {}

export type Values = {
	pitch: number?,
	yaw: number?,
	roll: number?,
	x: number?,
	y: number?,
	z: number?,
}
export type Pose = { [string]: Values }
export type Timing = { windup: number, active: number, recovery: number }

local KEYS = { "pitch", "yaw", "roll", "x", "y", "z" }

function Pose.smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Fast start, gentle stop: for strikes.
function Pose.snap(t: number): number
	t = math.clamp(t, 0, 1)
	return 1 - (1 - t) ^ 3
end

function Pose.lerp(a: Pose, b: Pose, t: number): Pose
	local out: Pose = {}
	for _, source in { a, b } do
		for joint in source do
			if not out[joint] then
				local va, vb = a[joint] or {}, b[joint] or {}
				local v: any = {}
				for _, k in KEYS do
					local x0, x1 = (va :: any)[k] or 0, (vb :: any)[k] or 0
					v[k] = x0 + (x1 - x0) * t
				end
				out[joint] = v
			end
		end
	end
	return out
end

-- Adds b into a (both poses), changing a.
function Pose.add(a: Pose, b: Pose)
	for joint, vb in b do
		local va: any = a[joint] or {}
		for _, k in KEYS do
			local x = (vb :: any)[k]
			if x then
				va[k] = (va[k] or 0) + x
			end
		end
		a[joint] = va
	end
end

-- Where an action is at `elapsed` seconds: rest -> windup -> strike -> rest.
-- Returns nil once it has finished (unless hold keeps the strike pose).
function Pose.action(anim: any, timing: Timing, elapsed: number): Pose?
	local w, a, r = timing.windup, timing.active, timing.recovery
	if elapsed < w then
		return Pose.lerp({}, anim.windup, Pose.smooth(elapsed / w))
	elseif elapsed < w + a then
		return Pose.lerp(anim.windup, anim.strike, Pose.snap((elapsed - w) / a))
	elseif anim.hold then
		return anim.strike
	elseif elapsed < w + a + r then
		return Pose.lerp(anim.recoverFrom or anim.strike, {}, Pose.smooth((elapsed - w - a) / r))
	end
	return nil
end

function Pose.toCFrame(v: Values): CFrame
	return CFrame.new(v.x or 0, v.y or 0, v.z or 0)
		* CFrame.fromEulerAnglesYXZ(
			math.rad(v.pitch or 0),
			math.rad(v.yaw or 0),
			math.rad(v.roll or 0)
		)
end

return Pose
