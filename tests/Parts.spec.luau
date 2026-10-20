local T = require("./TestKit")
local Parts = require("../src/shared/Rules/Parts")
local Monsters = require("../src/shared/Config/Monsters")

T.test("a part breaks once when it crosses its threshold", function()
	local m = Monsters.Thornjaw
	local dmg, broken = Parts.applyPartDamage(m, {}, "head", 100)
	T.equal(#broken, 0)
	dmg, broken = Parts.applyPartDamage(m, dmg, "head", 60)
	T.equal(broken[1], "head")
	dmg, broken = Parts.applyPartDamage(m, dmg, "head", 500)
	T.equal(#broken, 0, "breaks only once")
	T.equal(dmg.head, 660)
end)

T.test("unbreakable parts never break", function()
	local _, broken = Parts.applyPartDamage(Monsters.Thornjaw, {}, "body", 99999)
	T.equal(#broken, 0)
end)
