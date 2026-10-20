--!strict
-- What each monster can drop. weight is relative: a 30 is three times as likely as a 10.
-- rolls: how many items a carve or quest reward gives.

return {
	Cinderwing = {
		rolls = 3,
		drops = {
			{ item = "CinderwingScale", weight = 40 },
			{ item = "CinderwingShell", weight = 30 },
			{ item = "FlameSac", weight = 20 },
			{ item = "CinderwingPlate", weight = 10 },
		},
		breakRewards = {
			head = "CinderwingPlate",
			wing = "CinderwingMembrane",
			tail = "CinderwingTail",
		},
	},
	Puffgourd = {
		rolls = 3,
		drops = {
			{ item = "PuffgourdHide", weight = 50 },
			{ item = "SporeCap", weight = 35 },
			{ item = "MarshGel", weight = 15 },
		},
		breakRewards = { pod = "GlowLantern", head = "PuffgourdLip" },
	},
	Thornjaw = {
		rolls = 3,
		drops = {
			{ item = "ThornjawScale", weight = 50 },
			{ item = "ThornjawHide", weight = 35 },
			{ item = "ThornjawCrest", weight = 15 },
		},
		breakRewards = { head = "ThornjawCrest" },
	},
}
