--!strict
-- Icons for the camp menus and currencies. The art is 3D-rendered in the game's style and lives
-- in assets/ui/icons/ (256 px PNGs). Roblox only shows uploaded images, so until each one is
-- uploaded and its id pasted into `image` here, the tile shows `emoji` instead.
-- Upload: Studio > View > Asset Manager > Bulk Import, pick the PNGs, then right-click each >
-- Copy Asset ID and paste it as "rbxassetid://<id>" (SETUP.md 8).
-- Emoji are kept to Emoji 12.1 and older without joiners, which Roblox draws on every device.

export type Icon = { image: string, emoji: string }

local icons: { [string]: Icon } = {
	Gear = { image = "", emoji = "⚔️" },
	Quests = { image = "", emoji = "📜" },
	Codex = { image = "", emoji = "📖" },
	Eggs = { image = "", emoji = "🥚" },
	Areas = { image = "", emoji = "🧭" },
	Skills = { image = "", emoji = "⭐" },
	Profile = { image = "", emoji = "👤" },
	Codes = { image = "", emoji = "🔑" },
	Rewards = { image = "", emoji = "🎁" },
	Lodge = { image = "", emoji = "🏕️" },
	Store = { image = "", emoji = "🛒" },
	RiftPass = { image = "", emoji = "🎟️" },
	-- Currencies: the pills draw a colored coin until these are uploaded.
	Gold = { image = "", emoji = "" },
	Shard = { image = "", emoji = "" },
}

return icons
