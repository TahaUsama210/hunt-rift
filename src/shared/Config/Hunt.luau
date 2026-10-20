--!strict
-- The hunting ground: what spawns where, what players carry, and how forgiving hit checks are.

return {
	startingWeapon = "IronGreatSword",
	playerMaxHp = 150,
	-- Walk speed while swinging, so heavy attacks commit you.
	swingWalkSpeed = 5,
	-- position is { x, y, z } in studs; the monster is dropped onto whatever ground is below.
	spawns = {
		{ monsterId = "Thornjaw", position = { 0, 0, -50 } },
		-- Far enough from Thornjaw that neither notices players fighting the other.
		{ monsterId = "Puffgourd", position = { -160, 0, 40 } },
	},
	-- Seconds a slain monster's body stays, and seconds until a fresh one spawns.
	corpseSeconds = 6,
	respawnSeconds = 12,
	-- Slack the server gives a player's hit for network lag.
	lagGraceSeconds = 0.35,
	lagGraceStuds = 6,
}
