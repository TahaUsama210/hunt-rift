local T = require("./TestKit")
local Monsters = require("../src/shared/Config/Monsters")
local Weapons = require("../src/shared/Config/Weapons")
local Hunt = require("../src/shared/Config/Hunt")

local function loadRig(name)
	return require(`../src/shared/Rigs/{name}`)
end

T.test("every spawn is a monster with a rig and ai", function()
	assert(Weapons[Hunt.startingWeapon], "starting weapon does not exist")
	for _, spawn in Hunt.spawns do
		local monster = Monsters[spawn.monsterId]
		assert(monster, `{spawn.monsterId} does not exist`)
		assert(monster.rig and monster.ai, `{spawn.monsterId} needs a rig and ai to spawn`)
	end
end)

T.test("rigs cover every hitzone and only use real ones", function()
	for id, monster in Monsters do
		if monster.rig then
			local rig = loadRig(monster.rig)
			local seen = {}
			for _, seg in rig.segments do
				assert(monster.hitzones[seg.hitzone], `{id} rig uses unknown hitzone {seg.hitzone}`)
				seen[seg.hitzone] = true
				if seg.breaksWith then
					assert(
						monster.breakHp[seg.breaksWith],
						`{seg.name} breaks with an unbreakable part`
					)
				end
			end
			for part in monster.hitzones do
				assert(seen[part], `{id} has no {part} in its rig`)
			end
		end
	end
end)

T.test("rig pieces attach to pieces that exist, and stay under the mesh budget", function()
	for id, monster in Monsters do
		if monster.rig then
			local rig = loadRig(monster.rig)
			local names, joints, total = { Root = true }, {}, 0
			for _, seg in rig.segments do
				assert(
					names[seg.attach],
					`{seg.name} attaches to {seg.attach}, which comes later or is missing`
				)
				names[seg.name] = true
				if seg.joint then
					assert(not joints[seg.joint], `two joints called {seg.joint}`)
					joints[seg.joint] = true
				end
				assert(seg.tris <= 20000, `{seg.name} is over Roblox's mesh limit`)
				total += seg.tris
			end
			assert(total <= 7000, `{id} mesh budget is {total} triangles`)
			for _, d in rig.details do
				assert(names[d.segment], `detail on missing segment {d.segment}`)
				assert(rig.colors[d.color], `unknown color {d.color}`)
			end
			for action, anim in rig.animations do
				for _, pose in { anim.windup, anim.strike, anim.recoverFrom or {} } do
					for joint in pose do
						assert(joints[joint], `{action} moves unknown joint {joint}`)
					end
				end
			end
			for name, attack in monster.ai.attacks do
				assert(rig.animations[name], `{id} attack {name} has no animation`)
				if attack.lostWith then
					assert(
						monster.breakHp[attack.lostWith],
						`{id}.{name} is lost with an unbreakable part`
					)
				end
			end
			assert(rig.animations.flinch and rig.animations.death, `{id} needs flinch and death`)
			for part, action in monster.ai.breakActions or {} do
				assert(monster.breakHp[part], `{id} has a break action for unbreakable {part}`)
				local anim = rig.animations[action]
				assert(
					anim and anim.timing,
					`{id} break action {action} needs an animation with timing`
				)
			end
			local gait = rig.gait
			for _, group in { gait.legs, gait.knees } do
				for joint in group do
					assert(joints[joint], `{id} walk cycle moves unknown joint {joint}`)
				end
			end
			for _, joint in gait.tail do
				assert(joints[joint], `{id} tail sway moves unknown joint {joint}`)
			end
			for name in rig.fallsOff do
				assert(names[name], `{id} fallsOff names unknown segment {name}`)
			end
		end
	end
end)
