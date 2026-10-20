--!strict
-- Builds a monster model from its body plan in Shared/Rigs, with Motor6D joints so it can
-- animate. Uses the imported mesh in ServerStorage.Assets.<rig name> when it is there (see
-- tools/blender), and plain parts for anything missing, so the game always has a monster.

local ServerStorage = game:GetService("ServerStorage")

local MonsterRig = {}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function placed(pos: { number }, rot: { number }?): CFrame
	local r = rot or { 0, 0, 0 }
	return CFrame.new(v3(pos)) * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
end

local function setup(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function primitive(rig: any, spec: any): BasePart
	local part: BasePart = if spec.shape == "wedge"
		then Instance.new("WedgePart")
		else Instance.new("Part")
	part.Size = v3(spec.size)
	part.CFrame = placed(spec.pos, spec.rot)
	local c = rig.colors[spec.color]
	part.Color = Color3.fromRGB(c[1], c[2], c[3])
	part.Material = if rig.glow[spec.color] then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if spec.shape == "ellipsoid" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	setup(part)
	return part
end

-- The imported mesh pieces, moved into rig space using the template's Root cube as the anchor.
-- Works whatever scale or rotation the importer used.
local function meshPieces(rig: any, rigName: string): { [string]: BasePart }
	local pieces = {}
	local assets = ServerStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild(rigName)
	-- Search the whole template: the importer sometimes wraps the pieces in an extra model.
	local anchor = template and template:FindFirstChild("Root", true)
	if not (template and anchor and anchor:IsA("BasePart")) then
		return pieces
	end
	local scale = rig.rootSize[1] / anchor.Size.X
	local rootCFrame = CFrame.new(0, rig.hipHeight, 0)
	local skin = template:FindFirstChildOfClass("SurfaceAppearance")
	for _, seg in rig.segments do
		local source = template:FindFirstChild(seg.name, true)
		if source and source:IsA("BasePart") then
			local rel = anchor.CFrame:ToObjectSpace(source.CFrame)
			local piece = source:Clone()
			piece.Size *= scale
			piece.CFrame = rootCFrame * CFrame.new(rel.Position * scale) * rel.Rotation
			if skin and not piece:FindFirstChildOfClass("SurfaceAppearance") then
				skin:Clone().Parent = piece
			end
			setup(piece)
			pieces[seg.name] = piece
		end
	end
	return pieces
end

local function joint(class: string, name: string, p0: BasePart, p1: BasePart, at: CFrame)
	local j = Instance.new(class) :: any
	j.Name = name
	j.Part0 = p0
	j.Part1 = p1
	j.C0 = p0.CFrame:Inverse() * at
	j.C1 = p1.CFrame:Inverse() * at
	j.Parent = p1
end

-- Returns the model with its Root at (0, hipHeight, 0), facing -Z. PivotTo it into place.
function MonsterRig.build(rig: any, rigName: string): Model
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = v3(rig.rootSize)
	root.CFrame = CFrame.new(0, rig.hipHeight, 0)
	root.Transparency = 1
	setup(root)
	root.Massless = false
	root.CanQuery = false
	root.Parent = model
	model.PrimaryPart = root

	local meshes = meshPieces(rig, rigName)
	local built: { [string]: BasePart } = { Root = root }
	for _, seg in rig.segments do
		local part = meshes[seg.name] or primitive(rig, seg)
		part.Name = seg.name
		part:SetAttribute("Hitzone", seg.hitzone)
		if seg.breaksWith and rig.fallsOff and rig.fallsOff[seg.name] then
			part:SetAttribute("FallsOffWith", seg.breaksWith)
		end
		part.Parent = model
		built[seg.name] = part
		local parent = built[seg.attach]
		joint(
			if seg.joint then "Motor6D" else "Weld",
			seg.joint or seg.name,
			parent,
			part,
			CFrame.new(v3(seg.jointAt))
		)
	end

	-- Decoration is already baked into the mesh pieces, so it is only added to plain parts.
	for _, d in rig.details do
		local seg = built[d.segment]
		if not meshes[d.segment] then
			local part = primitive(rig, d)
			part.Name = d.segment .. "Detail"
			part.CanQuery = false
			part:SetAttribute("FallsOffWith", seg:GetAttribute("FallsOffWith"))
			part.Parent = model
			local weld = Instance.new("Weld")
			weld.Part0 = seg
			weld.Part1 = part
			weld.C0 = seg.CFrame:Inverse() * part.CFrame
			weld.Parent = part
		end
	end
	model:SetAttribute("UsesMesh", next(meshes) ~= nil)
	return model
end

return MonsterRig
