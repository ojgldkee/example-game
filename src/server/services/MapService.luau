--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapService = {}
local mapModel: Model? = nil

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addNeonStrip(parent: Instance, cf: CFrame, size: Vector3, color: Color3)
	local p = part("NeonStrip", size, cf, color, parent, Enum.Material.Neon)
	p.CanCollide = false
	return p
end

local function buildSection(parent: Instance, index: number, z: number)
	local section = Instance.new("Model")
	section.Name = string.format("Section_%02d", index)
	section.Parent = parent

	local baseColor = index % 2 == 0 and Color3.fromRGB(45, 190, 255) or Color3.fromRGB(255, 95, 190)
	part("Floor", Vector3.new(Config.Map.CourseWidth, 2, Config.Map.SectionLength), CFrame.new(0, Config.Map.FloorY, z), Color3.fromRGB(32, 34, 46), section)
	addNeonStrip(section, CFrame.new(-Config.Map.CourseWidth/2 + 1, 1.1, z), Vector3.new(1, 0.25, Config.Map.SectionLength), baseColor)
	addNeonStrip(section, CFrame.new(Config.Map.CourseWidth/2 - 1, 1.1, z), Vector3.new(1, 0.25, Config.Map.SectionLength), baseColor)

	local pattern = ((index - 1) % 5) + 1
	if pattern == 1 then
		for i = 1, 6 do
			local x = (i % 2 == 0) and 8 or -8
			part("JumpPad", Vector3.new(10, 2, 7), CFrame.new(x, 4 + (i % 3), z - 24 + i * 8), baseColor, section)
		end
	elseif pattern == 2 then
		for i = 1, 5 do
			part("Beam", Vector3.new(5, 1.5, 9), CFrame.new((i - 3) * 7, 3 + i * 1.2, z - 24 + i * 9) * CFrame.Angles(0, math.rad(i * 15), 0), baseColor, section)
		end
	elseif pattern == 3 then
		for i = 1, 4 do
			local p = part("MovingPlatform", Vector3.new(9, 1.5, 9), CFrame.new((i % 2 == 0 and 10 or -10), 4, z - 22 + i * 11), baseColor, section)
			p:SetAttribute("MoveAxis", i % 2 == 0 and "X" or "Y")
			p:SetAttribute("MoveDistance", 8 + i)
			p:SetAttribute("MoveSpeed", 1.2 + i * 0.15)
		end
	elseif pattern == 4 then
		for i = 1, 7 do
			local p = part("FallingTile", Vector3.new(8, 1, 6), CFrame.new(((i % 3) - 1) * 9, 3, z - 25 + i * 7), baseColor, section)
			p:SetAttribute("FallingTile", true)
		end
	else
		for i = 1, 5 do
			local bar = part("Spinner", Vector3.new(28, 1, 2), CFrame.new(0, 4, z - 22 + i * 11), Color3.fromRGB(255, 230, 70), section, Enum.Material.Neon)
			bar:SetAttribute("Spinner", true)
			bar:SetAttribute("SpinSpeed", 35 + i * 8)
		end
	end

	local checkpoint = part("Checkpoint", Vector3.new(12, 1, 4), CFrame.new(0, 2, z + Config.Map.SectionLength/2 - 6), Color3.fromRGB(75, 255, 130), section, Enum.Material.Neon)
	checkpoint:SetAttribute("CheckpointIndex", index)
end

function MapService.Build()
	if mapModel then mapModel:Destroy() end
	mapModel = Instance.new("Model")
	mapModel.Name = "GeneratedPlayground"
	mapModel.Parent = Workspace

	local total = Config.Map.SectionCount
	for i = 1, total do
		local z = Config.Map.StartZ + (i - 1) * Config.Map.SectionLength
		buildSection(mapModel, i, z)
	end

	local finishZ = Config.Map.StartZ + total * Config.Map.SectionLength
	part("Finish", Vector3.new(Config.Map.CourseWidth, 2, 18), CFrame.new(0, 1, finishZ), Color3.fromRGB(255, 215, 60), mapModel, Enum.Material.Neon)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 3, Config.Map.StartZ - 28)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = mapModel

	return mapModel
end

function MapService.GetMap()
	return mapModel
end

function MapService.Init(_services)
	MapService.Build()
end

return MapService
