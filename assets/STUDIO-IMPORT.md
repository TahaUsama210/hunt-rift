# Seeing the Hunt Rift monsters in Roblox Studio

These steps show a monster in Studio so you can walk around it and check its size and look.
On its own the import is only the body. A monster moves and fights once the game thread has
wired it in (stats, AI, loot and animations in `src/`, which arrive with `git pull`). There is
no animation file to import: the game animates the mesh pieces by name. Wired so far:
Puffgourd (spawns at -160, 0, 40). For a wired monster, do steps 1 and 4 and press Play.

## 1. Import one monster
1. `git pull` in your hunt-rift folder. Each monster has its own folder, for example
   `assets/Shardkite/`. Rojo doesn't turn FBX files into meshes, so meshes still go in by hand once.
2. In Studio: **Home > Import 3D** (or **File > Import 3D**) and pick `assets/Shardkite/Shardkite.fbx`.
3. In the import window, keep it as **one model** (don't merge meshes), leave textures on, and
   click **Import**. It lands in Workspace as a model with pieces named Body, Head, WingR, and so on,
   plus a small `Root` cube.

## 2. If it comes in grey
Every piece shares one texture atlas, so you only set it up once:
1. Select the model, then **+ > SurfaceAppearance** inside each piece, or run the snippet below.
2. Set **ColorMap** to `Shardkite_color.png` and **NormalMap** to `Shardkite_normal.png` (click the
   property box and pick the file, and Studio uploads it).

Command-bar snippet. Select the model first, then paste your two image ids:

```lua
local COLOR, NORMAL = "rbxassetid://PASTE_COLOR_ID", "rbxassetid://PASTE_NORMAL_ID"
local model = game.Selection:Get()[1]
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") then
		p.Anchored = true -- the pieces aren't jointed yet, so anchor them or they fall apart in Play
		if p.Name == "Root" then
			p.Transparency = 1
		elseif p:IsA("MeshPart") and not p:FindFirstChildOfClass("SurfaceAppearance") then
			local sa = Instance.new("SurfaceAppearance")
			sa.ColorMap, sa.NormalMap = COLOR, NORMAL
			sa.Parent = p
		end
	end
end
```

To get the ids, use **View > Asset Manager > Bulk Import**, pick the two PNGs, then right-click
each one and choose **Copy Asset ID**.

## 3. Look at it
- Anchor the whole model (the snippet does this), press **Play** and walk around it.
- The files import at their real size: the `Root` cube comes in 2 studs wide. (Before
  2026-10-20 they came in 100 times too big because Studio reads the FBX numbers as studs. If a
  monster you imported earlier is huge, delete it, `git pull` and import it again, or select it
  and run this in the command bar to shrink it from its Root cube:)

```lua
local m = game.Selection:Get()[1]; local r = m:FindFirstChild("Root", true); m:ScaleTo(m:GetScale() * 2 / r.Size.X); for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored = true end end; r.Transparency = 1; local cf, s = m:GetBoundingBox(); m:PivotTo(m:GetPivot() + Vector3.new(0, s.Y / 2 - cf.Position.Y, 0))
```

- Big monsters are meant to be big, about 2 to 5 times a player's height.
- Expected heights next to a 5-stud player: Shardkite 13, Burrowmaw 11, Puffgourd 11,
  Cragmaul 12, Vexmantis 13, Slagstrider 17, Riftwarden 26, Gnasher 5.5, Mossback 7.5,
  Glidewing 2.5 (it hovers).
- `<Name>_glow.png` marks the parts meant to glow (eyes, crystals, magma). Roblox textures
  have no glow channel, so the game will light those parts separately later.

## 4. Get it ready for the game
Rename the model to the monster's name and move it to **ServerStorage > Assets** (make the
folder if it's missing), then save the place. That's where the game looks for imported
meshes, the same as Thornjaw (SETUP.md step 7).
