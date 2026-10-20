local T = require("./TestKit")
local PortalParty = require("../src/shared/Rules/PortalParty")
local NestRotation = require("../src/shared/Rules/NestRotation")
local Hub = require("../src/shared/Config/Hub")
local Monsters = require("../src/shared/Config/Monsters")
local Icons = require("../src/shared/Config/Icons")

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

T.test("every station hunter has a body plan that holds together", function()
	for _, station in Hub.stations do
		local rig = require(`../src/shared/Rigs/{station.rig}`)
		local names, joints, total = { Root = true }, {}, 0
		for _, seg in rig.segments do
			assert(names[seg.attach], `{station.rig}: {seg.name} attaches to missing {seg.attach}`)
			names[seg.name] = true
			if seg.joint then
				assert(not joints[seg.joint], `{station.rig}: two joints called {seg.joint}`)
				joints[seg.joint] = true
			end
			assert(rig.colors[seg.color], `{station.rig}: unknown color {seg.color}`)
			total += seg.tris
		end
		assert(total <= 7000, `{station.rig} mesh budget is {total} triangles`)
		for _, d in rig.details do
			assert(names[d.segment], `{station.rig}: detail on missing segment {d.segment}`)
			assert(rig.colors[d.color], `{station.rig}: unknown color {d.color}`)
		end
		for point, spot in rig.points or {} do
			assert(names[spot.segment], `{station.rig}: point {point} on missing {spot.segment}`)
		end
		local idle = rig.idle
		assert(idle, `{station.rig} needs an idle`)
		assert(
			not idle.waveWith or joints[idle.waveWith],
			`{station.rig} waves with a missing joint`
		)
		assert(not idle.work or joints[idle.work.joint], `{station.rig} works with a missing joint`)
		assert(not idle.float or joints.Float, `{station.rig} floats without a Float joint`)
		assert(not idle.orbit or joints.Orbit, `{station.rig} orbits without an Orbit joint`)
		assert(#station.lines > 0, `{station.id} has nothing to say`)
	end
end)

T.test("camp decorations stand on the plaza", function()
	local function onPlaza(p: { number }, what: string)
		local flat = math.sqrt(p[1] * p[1] + p[3] * p[3])
		assert(flat < Hub.plazaRadius - 4, `{what} at {p[1]}, {p[3]} is off the plaza`)
	end
	for _, p in Hub.braziers do
		onPlaza(p, "a brazier")
	end
	for _, pair in Hub.lanternStrings do
		onPlaza(pair[1], "a lantern pole")
		onPlaza(pair[2], "a lantern pole")
	end
end)

T.test("icons are uploaded ids or left empty", function()
	for name, icon in Icons do
		assert(
			icon.image == "" or string.match(icon.image, "^rbxassetid://%d+$"),
			`{name}: image should look like rbxassetid://123`
		)
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
