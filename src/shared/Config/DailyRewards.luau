--!strict
-- The 7-day login calendar. Claim once per UTC day; missing a day starts again at day 1, and
-- after day 7 the week starts over. shards are Rift Shards.

return {
	days = {
		{ gold = 200, shards = 10 },
		{ gold = 300, shards = 15 },
		{ gold = 400, shards = 20 },
		{ gold = 500, shards = 25 },
		{ gold = 600, shards = 30 },
		{ gold = 800, shards = 40 },
		{ gold = 1500, shards = 100 },
	},
}
