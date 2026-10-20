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

export type Station = {
	id: string,
	kind: string, -- which menu the client opens
	npc: string,
	title: string,
	position: { number },
	color: { number }, -- the NPC's signature color: awning, sign, glow and menu border
	rig: string, -- the NPC's body plan in Shared/Rigs
	marker: string?, -- a bouncing mark over the head ("!" for the quest giver)
	lines: { string }, -- what they say when you walk up
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

	-- Stations and the hunters who run them.
	stations = {
		{
			id = "Blacksmith",
			kind = "forge",
			npc = "Brannoc",
			title = "Blacksmith",
			position = { -45, 0, 8 },
			color = { 255, 138, 61 },
			rig = "Brannoc",
			lines = {
				"Bring me scales and I'll make 'em sing.",
				"Hot iron waits for no one!",
				"That blade of yours looks thirsty.",
			},
		},
		{
			id = "UpgradeTable",
			kind = "upgrade",
			npc = "Wren",
			title = "Upgrade Table",
			position = { -45, 0, 30 },
			color = { 79, 214, 255 },
			rig = "Wren",
			lines = {
				"Ooh, is that a Thornjaw fang? Gimme!",
				"One more stone and this thing glows. Probably.",
				"My upgrade bench is almost ready. Almost!",
			},
		},
		{
			id = "HuntingBoard",
			kind = "board",
			npc = "Hunt Master Odra",
			title = "Hunting Board",
			position = { 45, 0, 8 },
			color = { 122, 214, 92 },
			rig = "Odra",
			-- The quest giver: a bouncing "!" over the hat draws new hunters over.
			marker = "!",
			lines = {
				"Got a hunt for you, if you're brave enough.",
				"A Thornjaw's prowling Elderbough. Interested?",
				"Pick a contract. The board doesn't bite. Much.",
			},
		},
		{
			id = "Quartermaster",
			kind = "shop",
			npc = "Pell",
			title = "Quartermaster",
			position = { 45, 0, 30 },
			color = { 160, 107, 255 },
			rig = "Pell",
			lines = {
				"Gold for goods, goods for gold!",
				"My shop opens soon. Save up that gold!",
				"Heard you like shiny things. Me too.",
			},
		},
		{
			id = "NestSpire",
			kind = "nest",
			npc = "Nestkeeper Ama",
			title = "Nest Spire",
			position = { 0, 0, 0 },
			color = { 224, 91, 208 },
			rig = "Ama",
			lines = {
				"The nest stirs. A new egg is coming...",
				"Patience, hunter. Every egg hatches in time.",
				"Can you feel the rift humming?",
			},
		},
	} :: { Station },
	spawn = { 0, 0, 55 },

	-- Decoration. Braziers stand at these spots; each lantern string hangs between two poles
	-- (the ends are the tops of the poles).
	braziers = { { -18, 0, 46 }, { 18, 0, 46 }, { -30, 0, -24 }, { 30, 0, -24 } },
	lanternStrings = {
		{ { -14, 11, 38 }, { 14, 11, 38 } }, -- over the way in from the spawn
		{ { -36, 10, 2 }, { -36, 10, 36 } }, -- along the blacksmith and the upgrade table
		{ { 36, 10, 2 }, { 36, 10, 36 } }, -- along the hunting board and the quartermaster
	},

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
