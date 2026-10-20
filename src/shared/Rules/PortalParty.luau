--!strict
-- Who is standing on a portal, and when that party leaves for the hunt.
-- Pure: the server passes in who is on the pad each tick and the time.

local PortalParty = {}

export type Party = {
	members: { string }, -- in the order they stepped on; the first is the leader
	startedAt: number?, -- when the countdown began, nil while the pad is empty
	goNow: boolean, -- a member pressed Go, so leave on the next tick
}

export type Portal = { minRank: number, monsterId: string? }
export type PartyConfig = { maxSize: number, countdownSeconds: number }

function PortalParty.new(): Party
	return { members = {}, startedAt = nil, goNow = false }
end

-- Whether a hunter of this rank may use the portal, and why not.
function PortalParty.canEnter(portal: Portal, rank: number): (boolean, string?)
	if not portal.monsterId then
		return false, "Coming soon"
	end
	if rank < portal.minRank then
		return false, `Needs Rift Rank {portal.minRank}`
	end
	return true, nil
end

-- Updates the party from who is on the pad now. Members who stepped off leave, newcomers join
-- at the back while there is room. Returns the new party and whether it should leave now.
function PortalParty.step(
	party: Party,
	onPad: { string },
	now: number,
	config: PartyConfig
): (Party, boolean)
	local present = {}
	for _, id in onPad do
		present[id] = true
	end
	local members = {}
	local seen = {}
	for _, id in party.members do
		if present[id] then
			table.insert(members, id)
			seen[id] = true
		end
	end
	for _, id in onPad do
		if not seen[id] and #members < config.maxSize then
			table.insert(members, id)
			seen[id] = true
		end
	end

	if #members == 0 then
		return PortalParty.new(), false
	end
	local startedAt = party.startedAt or now
	local leave = party.goNow or now - startedAt >= config.countdownSeconds
	return { members = members, startedAt = startedAt, goNow = party.goNow }, leave
end

-- A member asks to leave right away. Anyone else is ignored.
function PortalParty.pressGo(party: Party, id: string): Party
	if table.find(party.members, id) then
		return { members = party.members, startedAt = party.startedAt, goNow = true }
	end
	return party
end

-- Whole seconds left on the countdown, for the party card.
function PortalParty.secondsLeft(party: Party, now: number, config: PartyConfig): number
	if not party.startedAt then
		return config.countdownSeconds
	end
	return math.max(0, math.ceil(config.countdownSeconds - (now - party.startedAt)))
end

return PortalParty
