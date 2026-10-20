--!strict
-- Rift Camp, the hub players spawn in, and the portals that start hunts.
-- Positions are { x, y, z } in studs. Hub positions are offsets from the hub's middle; a
-- portal's arrival is a world position in the hunting ground (dropped onto the ground below).
-- color is { r, g, b } from 0 to 255. Layout plan: the Hunt Rift hub and UI design canvas.

export type Portal = {
	id: string,
	displayName: string,
	color: { number },
	minRank: number,
	monsterId: string?,
	angle: number, -- degrees around the plaza: 90 is due north, 0 is east
	size: number?, -- 1 if left out
	arrival: { number },
}

return {
	-- The camp floats above the hunting ground, so the two never see each other.
	origin = { 0, 400, 0 },
	plazaRadius = 80,
	-- Every new hunter starts here until rift ranks are saved.
	startingRank = 1,

	party = {
		maxSize = 4,
		-- Seconds from the first hunter stepping on until the party leaves.
		countdownSeconds = 10,
		-- How close (studs, flat) to a portal's middle counts as standing on it.
		padRadius = 7,
	},

	-- Seconds after a monster is slain before the party is sent back to camp.
	returnSeconds = 10,
	-- How close (studs) a hunter must be to a station to use it.
	stationReach = 16,

	-- One portal per biome, laid out on an arc at the north of the plaza.
	-- monsterId = nil means nothing lives there yet, so the portal shows as coming soon.
	portals = {
		{
			id = "Elderbough",
			displayName = "Elderbough Canopy",
			color = { 91, 191, 90 },
			minRank = 1,
			monsterId = "Thornjaw",
			angle = 150,
			arrival = { 0, 0, 40 },
		},
		{
			id = "Frostspire",
			displayName = "Frostspire Cliffs",
			color = { 143, 211, 255 },
			minRank = 3,
			angle = 130,
			arrival = { 0, 0, 40 },
		},
		{
			id = "Sunscar",
			displayName = "Sunscar Dune Sea",
			color = { 232, 176, 74 },
			minRank = 2,
			angle = 110,
			arrival = { 0, 0, 40 },
		},
		{
			id = "ElderRift",
			displayName = "Elder Rift",
			color = { 224, 91, 208 },
			minRank = 4,
			angle = 90,
			size = 1.3,
			arrival = { 0, 0, 40 },
		},
		{
			id = "Glowmire",
			displayName = "Glowmire Fungal Marsh",
			color = { 176, 124, 255 },
			-- Rank 1 until rift ranks are saved, so new hunters can reach both monsters.
			minRank = 1,
			monsterId = "Puffgourd",
			angle = 70,
			arrival = { -160, 0, 100 },
		},
		{
			id = "Badlands",
			displayName = "Shattered Badlands",
			color = { 217, 119, 74 },
			minRank = 3,
			angle = 50,
			arrival = { 0, 0, 40 },
		},
		{
			id = "Emberdeep",
			displayName = "Emberdeep Caldera",
			color = { 255, 106, 61 },
			minRank = 4,
			angle = 30,
			arrival = { 0, 0, 40 },
		},
	} :: { Portal },
	-- Distance from the plaza's middle to the portal arc.
	portalArcRadius = 62,

	-- Stations and the hunters who run them. kind picks the menu the client opens.
	stations = {
		{
			id = "Blacksmith",
			kind = "forge",
			npc = "Brannoc",
			title = "Blacksmith",
			position = { -45, 0, 8 },
			color = { 242, 169, 59 },
		},
		{
			id = "UpgradeTable",
			kind = "upgrade",
			npc = "Wren",
			title = "Upgrade Table",
			position = { -45, 0, 30 },
			color = { 242, 169, 59 },
		},
		{
			id = "HuntingBoard",
			kind = "board",
			npc = "Hunt Master Odra",
			title = "Hunting Board",
			position = { 45, 0, 8 },
			color = { 60, 198, 184 },
		},
		{
			id = "Quartermaster",
			kind = "shop",
			npc = "Pell",
			title = "Quartermaster",
			position = { 45, 0, 30 },
			color = { 60, 198, 184 },
		},
		{
			id = "NestSpire",
			kind = "nest",
			npc = "Nestkeeper Ama",
			title = "Nest Spire",
			position = { 0, 0, 0 },
			color = { 224, 91, 208 },
		},
	},
	spawn = { 0, 0, 55 },

	-- Nest raids rotate through one featured egg at a time. Each cycle is periodSeconds long and
	-- the raid is open for the first raidSeconds of it; the rest is the countdown to the next egg.
	-- epoch is a Unix time the rotation counts from.
	nest = {
		epoch = 1792022400,
		periodSeconds = 3 * 24 * 3600,
		raidSeconds = 24 * 3600,
		eggs = { "Thornjaw", "Puffgourd", "Shardkite", "Cragmaul", "Burrowmaw", "Vexmantis" },
	},
}
