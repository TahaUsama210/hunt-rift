# Setting up your computer

Do these once, in order. Anything Claude Code can do for you, just ask it.

## 1. Core tools
1. **Roblox Studio**, signed in to your account.
2. **Claude Code** in the Claude desktop app (needs a Pro plan or higher).
3. **Git** (on Windows, Git for Windows also gives you Git Bash for the check script).
4. **Rokit**, which installs the exact tool versions this project pins in `rokit.toml`:
   - Windows (PowerShell): `irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex`
   - Mac: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
5. Put this `roblox-game` folder somewhere like `Documents/roblox-game`, open a terminal there and run
   `rokit install`. That gets Rojo, Selene, StyLua and Lune.
6. Run `rojo plugin install` to add the Rojo plugin to Studio.

## 2. Check the starter project works
In the project folder run the checks:
- Windows (PowerShell): `powershell -ExecutionPolicy Bypass -File scripts\check.ps1`
- Mac: `./scripts/check.sh`

The first Selene run downloads Roblox's API list, then all four checks should pass.

## 3. Sync code into Studio
1. In the project folder run `rojo serve`.
2. Open a new Baseplate in Studio, click the Rojo plugin, then Connect.
3. Press Play. The Output window should say `MonsterHunt server ready` and `MonsterHunt client ready`.
4. To keep gold, items and the daily reward streak between play sessions, publish the place once
   (File > Publish to Roblox), then turn on Game Settings > Security > **Enable Studio Access to
   API Services**. Without it everything still works, but each play test starts fresh.

## 4. Connect Claude Code to Studio (the built-in MCP)
1. In Studio, open the Assistant panel, click the three dots, then **Manage MCP Servers**.
2. Turn on **Enable Studio as MCP server**.
3. Copy the **Claude Code CLI** command it shows.
4. In Claude Code (opened in this project folder), say: "I have an MCP running, use this to connect"
   and paste the command. Studio must be open whenever Claude uses it.

## 5. API keys (only when you get to the asset pipelines)
Never paste a key into a Claude chat. Store each one as an environment variable yourself, then
Claude reads it by name. Run the line for your system and paste the key when it asks.

| Variable | Where to get it | Used for |
|---|---|---|
| `ROBLOX_API_KEY` | create.roblox.com > Creator Hub > All tools > Open Cloud > API Keys | uploading models and images |
| `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` | Cloudflare dashboard > Workers AI | Flux images and icons |
| `KAGGLE_USERNAME`, `KAGGLE_KEY` | kaggle.com > Settings > API > Create New Token | Hi3DGen 3D models on free GPUs |

Windows (PowerShell), one per key:
```powershell
$k = Read-Host "Paste ROBLOX_API_KEY"; [Environment]::SetEnvironmentVariable("ROBLOX_API_KEY", $k, "User"); Remove-Variable k
```
Mac (zsh), one per key:
```bash
read -s "k?Paste ROBLOX_API_KEY: " && echo "export ROBLOX_API_KEY='$k'" >> ~/.zshrc && unset k
```
Restart the terminal and Claude Code afterwards so they see the new variables.
For the Roblox key, give it only the Assets read/write permission it needs.

## 6. Optional extras for models
- **Blender** (free) so Claude can decimate 3D models to about 6,000 triangles (Roblox's
  limit is 20,000 per mesh) and bake detail into textures.
- Check the licence of any AI model before shipping what it makes. Some exclude certain countries.

## 7. Import the monster mesh (optional, the game works without it)
The game builds the Thornjaw from plain parts until the mesh is imported.
1. In Studio: Home > Import 3D (or File > Import 3D) and choose `assets/Thornjaw/Thornjaw.fbx`.
2. In the import window keep it as one model (do not merge meshes) and import textures, then
   click Import. It lands in Workspace as a model with pieces named Body, Head, TailA and so on.
3. Rename the model to `Thornjaw`. In the Explorer, add a Folder named `Assets` to
   ServerStorage and drag the model into it.
4. If the pieces came in without textures, select the model, add a SurfaceAppearance inside it
   and set its ColorMap to `Thornjaw_color.png` and NormalMap to `Thornjaw_normal.png`
   (pick each file in the property box and Studio uploads it)
   (each piece copies it). Claude Code with the Studio MCP can do this step for you.
5. Save the place (File > Save). ServerStorage is not managed by Rojo, so it stays put.

To remake the mesh after changing the body plan, see "Monster meshes" in CLAUDE.md.

## 8. Upload the menu icons (optional, emoji show until then)
The camp tiles use 3D-rendered icons from `assets/ui/icons/`. Roblox only shows uploaded images.
1. In Studio: **View > Asset Manager**, then **Bulk Import** and pick all the PNGs in
   `assets/ui/icons/`.
2. In the Asset Manager's Images folder, right-click each one > **Copy Asset ID**.
3. Paste it into `src/shared/Config/Icons.luau` as `image = "rbxassetid://<id>"` for the icon
   with the same name. Rojo syncs it; the tile swaps its emoji for the icon.
Claude Code with the Studio MCP can do steps 2 and 3 for you once the images are imported.

## What to build first
1. One monster you can hit, with hitzones and part breaks (rules are already here and tested).
2. Weapon input and hit detection on the client, sent through the `AttackHit` remote.
3. Quest start/finish, rewards and crafting UI.
4. Then models, VFX and sound through their own skills, one at a time.
