local T = require("./TestKit")
local PortalParty = require("../src/shared/Rules/PortalParty")
local NestRotation = require("../src/shared/Rules/NestRotation")
local Hub = require("../src/shared/Config/Hub")
local Monsters = require("../src/shared/Config/Monsters")

local party = { maxSize = 2, countdownSeconds = 10 }

T.test("first hunter on the pad starts the countdown", function()
	local p, leave = PortalParty.step(PortalParty.new(), { "a" }, 100, party)
	T.equal(p.startedAt, 100)
	T.equal(leave, false)
	T.equal(PortalParty.secondsLeft(p, 103.5, party), 7)
end)

T.test("party leaves when the countdown runs out", function()
	local p = PortalParty.step(PortalParty.new(), { "a" }, 100, party)
	local _, leave = PortalParty.step(p, { "a", "b" }, 109.9, party)
	T.equal(leave, false)
	local _, leaveLater = PortalParty.step(p, { "a", "b" }, 110, party)
	T.equal(leaveLater, true)
end)

T.test("full party turns away extra hunters and keeps join order", function()
	local p = PortalParty.step(PortalParty.new(), { "a" }, 0, party)
	p = PortalParty.step(p, { "c", "b", "a" }, 1, party)
	T.equal(#p.members, 2)
	T.equal(p.members[1], "a", "leader stays first")
	T.equal(p.members[2], "c")
end)

T.test("stepping off leaves the party, an empty pad resets", function()
	local p = PortalParty.step(PortalParty.new(), { "a", "b" }, 0, party)
	p = PortalParty.step(p, { "b" }, 1, party)
	T.equal(#p.members, 1)
	T.equal(p.members[1], "b")
	T.equal(p.startedAt, 0, "countdown keeps running")
	p = PortalParty.step(p, {}, 2, party)
	T.equal(#p.members, 0)
	T.equal(p.startedAt, nil)
end)

T.test("only a member can press go", function()
	local p = PortalParty.step(PortalParty.new(), { "a" }, 0, party)
	T.equal(PortalParty.pressGo(p, "z").goNow, false)
	p = PortalParty.pressGo(p, "a")
	local _, leave = PortalParty.step(p, { "a" }, 1, party)
	T.equal(leave, true)
end)

T.test("locked portals say why", function()
	local ok, why = PortalParty.canEnter({ minRank = 3, monsterId = "Thornjaw" }, 1)
	T.equal(ok, false)
	T.equal(why, "Needs Rift Rank 3")
	local soon, soonWhy = PortalParty.canEnter({ minRank = 1 }, 5)
	T.equal(soon, false)
	T.equal(soonWhy, "Coming soon")
	T.equal(PortalParty.canEnter({ minRank = 1, monsterId = "Thornjaw" }, 1), true)
end)

T.test("every portal with a monster points at one that can spawn", function()
	local ids = {}
	for _, portal in Hub.portals do
		assert(not ids[portal.id], `duplicate portal {portal.id}`)
		ids[portal.id] = true
		if portal.monsterId then
			local monster = Monsters[portal.monsterId]
			assert(monster, `{portal.id}: unknown monster {portal.monsterId}`)
			assert(monster.rig and monster.ai, `{portal.id}: {portal.monsterId} cannot spawn yet`)
		end
	end
end)

T.test("a new hunter can enter at least one portal", function()
	local any = false
	for _, portal in Hub.portals do
		if PortalParty.canEnter(portal, Hub.startingRank) then
			any = true
		end
	end
	T.equal(any, true)
end)

T.test("stations have a menu the client knows", function()
	local kinds = { forge = true, upgrade = true, board = true, shop = true, nest = true }
	for _, station in Hub.stations do
		assert(kinds[station.kind], `{station.id}: unknown kind {station.kind}`)
	end
end)

local schedule = { epoch = 0, periodSeconds = 100, raidSeconds = 30, eggs = { "A", "B", "C" } }

T.test("nest raid is open at the start of each cycle", function()
	local s = NestRotation.at(schedule, 10)
	T.equal(s.open, true)
	T.equal(s.egg, "A")
	T.equal(s.secondsLeft, 20)
end)

T.test("between raids the countdown shows the next egg", function()
	local s = NestRotation.at(schedule, 40)
	T.equal(s.open, false)
	T.equal(s.egg, "B")
	T.equal(s.secondsLeft, 60)
	local wrap = NestRotation.at(schedule, 250)
	T.equal(wrap.egg, "A", "after C comes A again")
	T.equal(NestRotation.at(schedule, 300).egg, "A", "cycle 3 raids A")
end)

T.test("countdown text", function()
	T.equal(NestRotation.format(2 * 86400 + 4 * 3600 + 12 * 60 + 5), "2d 04h 12m")
	T.equal(NestRotation.format(3 * 3600 + 5 * 60), "3h 05m")
	T.equal(NestRotation.format(249), "4m 09s")
end)
