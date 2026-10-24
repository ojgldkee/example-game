--!strict
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapService = {}
local mapModel: Model? = nil

local palette = {
	Blue = Color3.fromRGB(31,186,255),
	Pink = Color3.fromRGB(255,80,184),
	Yellow = Color3.fromRGB(255,218,67),
	Green = Color3.fromRGB(79,238,150),
	Purple = Color3.fromRGB(150,93,255),
	Orange = Color3.fromRGB(255,143,62),
	Red = Color3.fromRGB(255,73,92),
	Dark = Color3.fromRGB(30,32,43),
	Dark2 = Color3.fromRGB(18,20,28),
	Cream = Color3.fromRGB(247,236,201),
	White = Color3.fromRGB(245,248,255),
}

local stageNames = {
	"WARM UP",
	"BALANCE BLOCKS",
	"MOVING PLAYGROUND",
	"DROP FLOOR",
	"SWEEPER ROOM",
	"BOUNCE TUNNEL",
	"CONVEYOR CHAOS",
	"LASER WEAVE",
	"SKY STEPS",
	"DOUBLE TROUBLE",
	"PICK A PATH",
	"FINAL GAUNTLET",
}

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

local function neon(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance)
	local p = part(name, size, cf, color, parent, Enum.Material.Neon)
	p.CanCollide = false
	return p
end

local function sign(parent: Instance, text: string, cf: CFrame, size: Vector3, color: Color3)
	local board = part("Sign", size, cf, palette.Dark2, parent)
	board.CanCollide = false

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 35
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = gui
	return board
end

local function arch(parent: Instance, z: number, color: Color3)
	part("ArchL", Vector3.new(3,22,4), CFrame.new(-Config.Map.CourseWidth/2+2,11,z), color, parent)
	part("ArchR", Vector3.new(3,22,4), CFrame.new(Config.Map.CourseWidth/2-2,11,z), color, parent)
	part("ArchTop", Vector3.new(Config.Map.CourseWidth,3,4), CFrame.new(0,22,z), color, parent)
end

local function safePlatform(parent: Instance, name: string, x: number, y: number, z: number, sx: number, sz: number, color: Color3)
	return part(name, Vector3.new(sx,1.5,sz), CFrame.new(x,y,z), color, parent, Enum.Material.SmoothPlastic)
end

local function hazardDamageForStage(stageIndex: number): number
	if stageIndex <= 4 then
		return Config.Obby.EarlyHazardDamage
	elseif stageIndex <= 8 then
		return Config.Obby.MidHazardDamage
	end
	return Config.Obby.LateHazardDamage
end

local function hazardFloor(parent: Instance, z: number, stageIndex: number)
	local hazard = part(
		"HazardFloor",
		Vector3.new(Config.Map.CourseWidth-8, 0.8, Config.Map.SectionLength-24),
		CFrame.new(0, Config.Obby.HazardY, z),
		palette.Red,
		parent,
		Enum.Material.Neon
	)
	hazard.Transparency = 0.12
	hazard:SetAttribute("HazardPart", true)
	hazard:SetAttribute("HazardDamage", hazardDamageForStage(stageIndex))
	return hazard
end

local function damageBeam(parent: Instance, name: string, size: Vector3, cf: CFrame, damage: number)
	local beam = part(name, size, cf, palette.Red, parent, Enum.Material.Neon)
	beam.CanCollide = false
	beam:SetAttribute("DamagePart", true)
	beam:SetAttribute("Damage", damage)
	return beam
end

local function spinner(parent: Instance, z: number, speed: number, radius: number?)
	local r = radius or 13
	part("SpinnerPole", Vector3.new(2,7,2), CFrame.new(0,3.5,z), palette.Cream, parent)
	local bar = damageBeam(parent, "Spinner", Vector3.new(r*2,1.2,1.6), CFrame.new(0,4.2,z), Config.Obby.LaserDamage)
	bar:SetAttribute("Spinner", true)
	bar:SetAttribute("SpinSpeed", speed)
	return bar
end

local function buildShell(section: Instance, z: number, color: Color3, stageIndex: number)
	-- The old course put the red hazard almost flush with the platforms.
	-- V2 leaves ~7 studs of vertical separation so tiny edge touches are not instant failures.
	part(
		"DeepFloor",
		Vector3.new(Config.Map.CourseWidth,1.5,Config.Map.SectionLength),
		CFrame.new(0, Config.Obby.HazardY - 1.2, z),
		palette.Dark2,
		section,
		Enum.Material.SmoothPlastic
	)

	part("WallL", Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength), CFrame.new(-Config.Map.CourseWidth/2,Config.Map.WallHeight/2,z), Color3.fromRGB(36,40,54), section)
	part("WallR", Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength), CFrame.new(Config.Map.CourseWidth/2,Config.Map.WallHeight/2,z), Color3.fromRGB(36,40,54), section)
	part("Ceiling", Vector3.new(Config.Map.CourseWidth,2,Config.Map.SectionLength), CFrame.new(0,Config.Map.CeilingHeight,z), Color3.fromRGB(22,24,33), section)

	neon("RailL", Vector3.new(.7,.4,Config.Map.SectionLength), CFrame.new(-Config.Map.CourseWidth/2+1.7,1.8,z), color, section)
	neon("RailR", Vector3.new(.7,.4,Config.Map.SectionLength), CFrame.new(Config.Map.CourseWidth/2-1.7,1.8,z), color, section)

	for i=-2,2 do
		local lamp = neon("CeilingLight", Vector3.new(5,.35,1.3), CFrame.new(i*9,Config.Map.CeilingHeight-1.2,z), color, section)
		lamp:SetAttribute("WakeLight", true)
	end

	local startZ = z - Config.Map.SectionLength/2
	local endZ = z + Config.Map.SectionLength/2

	arch(section, startZ + 2, color)
	arch(section, endZ - 2, color)

	-- Entry and checkpoint platforms touch the neighboring sections, so every level
	-- is connected without requiring an oversized transition jump.
	safePlatform(section, "StageEntry", 0, 2.6, startZ + 6, 22, 12, color)
	local checkpoint = safePlatform(section, "Checkpoint", 0, 2.6, endZ - 6, 22, 12, palette.Green)
	checkpoint.Material = Enum.Material.Neon
	checkpoint:SetAttribute("CheckpointIndex", stageIndex)

	sign(
		section,
		("STAGE %02d / %02d\n%s"):format(stageIndex, Config.Map.SectionCount, stageNames[stageIndex]),
		CFrame.new(0,13,startZ+3) * CFrame.Angles(0,math.pi,0),
		Vector3.new(28,7,.7),
		color
	)
end

local function playableRange(z: number): (number, number)
	local startZ = z - Config.Map.SectionLength/2 + 15
	local endZ = z + Config.Map.SectionLength/2 - 15
	return startZ, endZ
end

local builders: {[number]: (Instance, number, Color3, number) -> ()} = {}

-- 1: warm-up pads. All required clear gaps are under ~4.5 studs.
builders[1] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	local xs = {0,-4,4,-4,4,0}
	for i,x in ipairs(xs) do
		safePlatform(section, "WarmupPad", x, 3.1 + ((i%3)==0 and .35 or 0), startZ + (i-1)*9.2, 13, 8.2, color)
	end
end

-- 2: wide balance blocks, rotated visually but with generous width.
builders[2] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	local xs = {-5,5,-4,4,-3,3}
	for i,x in ipairs(xs) do
		local p = safePlatform(section, "BalanceBlock", x, 3.2, startZ + (i-1)*9.0, 10.5, 8.0, color)
		p.CFrame *= CFrame.Angles(0, math.rad((i%2==0) and 8 or -8), 0)
	end
end

-- 3: slow moving platforms. Movement is deliberately small enough that players
-- can wait for alignment instead of needing a precision leap.
builders[3] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,5 do
		local x = (i%2==0) and 3.5 or -3.5
		local p = safePlatform(section, "MovingPlatform", x, 3.4, startZ + (i-1)*10.4, 13, 9.5, color)
		p:SetAttribute("MoveAxis", "X")
		p:SetAttribute("MoveDistance", 4.25 + (stageIndex-1)*0.08)
		p:SetAttribute("MoveSpeed", 0.8 + i*0.06)
	end
end

-- 4: falling tiles. Large tiles and a longer warning delay than the old version.
builders[4] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,8 do
		local x = ((i%3)-1)*4.2
		local p = safePlatform(section, "FallingTile", x, 3.1, startZ + (i-1)*7.1, 11.5, 7.4, color)
		p:SetAttribute("FallingTile", true)
		p:SetAttribute("FallDelay", 0.55)
	end
end

-- 5: sweepers on large islands.
builders[5] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,4 do
		local islandZ = startZ + (i-1)*13.0
		safePlatform(section, "SweeperIsland", 0, 3.0, islandZ, 26, 10.5, color)
		spinner(section, islandZ, 24 + i*4, 11)
	end
end

-- 6: bounce tunnel. Bounce pads move the player upward; landing islands are huge.
builders[6] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,5 do
		local pad = safePlatform(section, "BouncePad", (i%2==0) and 4 or -4, 3.0, startZ + (i-1)*10.2, 12, 9, palette.Yellow)
		pad.Material = Enum.Material.Neon
		pad:SetAttribute("BouncePad", true)
		pad:SetAttribute("BounceVelocity", Config.Obby.BounceVelocity)
	end
end

-- 7: conveyor platforms. They assist/oppose movement but do not require sprinting.
builders[7] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,6 do
		local p = safePlatform(section, "Conveyor", (i%2==0) and 3 or -3, 3.0, startZ + (i-1)*8.4, 12.5, 8.6, color)
		p:SetAttribute("Conveyor", true)
		p:SetAttribute("ConveyorSpeed", (i%2==0) and 8 or -5)
	end
end

-- 8: laser weave. Safe floor, clearly visible damage beams; this is a dodge stage,
-- not a platforming stage.
builders[8] = function(section, z, color, _stageIndex)
	local startZ, _ = playableRange(z)
	safePlatform(section, "LaserFloor", 0, 2.8, z, 34, Config.Map.SectionLength-24, color)
	for i=1,6 do
		local beamZ = startZ + (i-1)*8.7
		if i%2==0 then
			damageBeam(section, "Laser", Vector3.new(18,4,1), CFrame.new(-8,4.6,beamZ), Config.Obby.LaserDamage)
		else
			damageBeam(section, "Laser", Vector3.new(18,4,1), CFrame.new(8,4.6,beamZ), Config.Obby.LaserDamage)
		end
	end
end

-- 9: ascending sky steps. Height gain is only 0.65 studs per jump.
builders[9] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,7 do
		local y = 3.0 + (i-1)*0.65
		local x = (i%2==0) and 4.2 or -4.2
		safePlatform(section, "SkyStep", x, y, startZ + (i-1)*7.8, 12, 7.6, color)
	end
end

-- 10: moving islands + one gentle sweeper.
builders[10] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,5 do
		local islandZ = startZ + (i-1)*10.4
		local p = safePlatform(section, "ComboIsland", (i%2==0) and 3.5 or -3.5, 3.2, islandZ, 13, 9.4, color)
		if i==2 or i==4 then
			p:SetAttribute("MoveAxis","X")
			p:SetAttribute("MoveDistance",3.8)
			p:SetAttribute("MoveSpeed",0.95)
		end
	end
	spinner(section, z+3, 30, 10)
end

-- 11: two-lane choice. Both lanes are beatable; red markers are warnings, not hidden traps.
builders[11] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	for i=1,6 do
		local laneX = (i%2==0) and 7 or -7
		safePlatform(section, "ChoiceTile", laneX, 3.1, startZ + (i-1)*8.7, 12.5, 8.7, color)
		-- Center rescue tile keeps the route forgiving if the player changes lanes.
		if i==3 or i==5 then
			safePlatform(section, "RescueTile", 0, 3.0, startZ + (i-1)*8.7, 9, 7.2, palette.Cream)
		end
	end
end

-- 12: final gauntlet. Harder, but every required jump is still within the same
-- calibrated clear-gap envelope as earlier stages.
builders[12] = function(section, z, color, stageIndex)
	hazardFloor(section, z, stageIndex)
	local startZ, _ = playableRange(z)
	local xs = {0,-4,4,0,-4,4}
	for i,x in ipairs(xs) do
		local islandZ = startZ + (i-1)*9.0
		local p = safePlatform(section, "FinalIsland", x, 3.2 + ((i==4) and .6 or 0), islandZ, 12, 8.3, color)
		if i==3 then
			p:SetAttribute("MoveAxis","X")
			p:SetAttribute("MoveDistance",3.5)
			p:SetAttribute("MoveSpeed",1.0)
		end
	end
	spinner(section, z+9, 34, 10)
end

local function buildSection(parent: Instance, stageIndex: number, z: number)
	local section = Instance.new("Model")
	section.Name = ("Section_%02d_%s"):format(stageIndex, string.gsub(stageNames[stageIndex]," ","_"))
	section:SetAttribute("StageIndex", stageIndex)
	section:SetAttribute("StageName", stageNames[stageIndex])
	section.Parent = parent

	local colors = {palette.Blue,palette.Pink,palette.Yellow,palette.Green,palette.Purple,palette.Orange}
	local color = colors[((stageIndex-1)%#colors)+1]

	buildShell(section, z, color, stageIndex)
	builders[stageIndex](section, z, color, stageIndex)
end

local function buildLobby(parent: Instance)
	local firstStageStart = Config.Map.StartZ - Config.Map.SectionLength/2
	local centerZ = firstStageStart - Config.Map.LobbyLength/2

	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.Parent = parent

	part("LobbyFloor", Vector3.new(76,2,Config.Map.LobbyLength), CFrame.new(0,0,centerZ), Color3.fromRGB(42,45,60), lobby, Enum.Material.Rubber)
	part("BackWall", Vector3.new(76,28,2), CFrame.new(0,14,centerZ-Config.Map.LobbyLength/2), palette.Dark2, lobby)

	sign(lobby, "HAPPY'S PLAYPLACE", CFrame.new(0,16,centerZ-Config.Map.LobbyLength/2+1.2), Vector3.new(42,8,.8), palette.Yellow)
	sign(lobby, "12 STAGES • EVERY DEATH WAKES HAPPY", CFrame.new(0,8,centerZ-Config.Map.LobbyLength/2+1.3), Vector3.new(42,4.5,.8), palette.Red)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(20,1,16)
	spawn.CFrame = CFrame.new(0,3,firstStageStart-10)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = palette.Green
	spawn.Material = Enum.Material.Neon
	spawn.Parent = lobby

	-- Continuous bridge from lobby into Stage 1.
	safePlatform(lobby, "LobbyBridge", 0, 2.4, firstStageStart-2, 22, 16, palette.Green)

	for i=-2,2 do
		local bench = part("Bench", Vector3.new(8,2,3), CFrame.new(i*13,2,centerZ), (i%2==0) and palette.Blue or palette.Pink, lobby)
		bench:SetAttribute("Decor", true)
	end
end

local function buildFinish(parent: Instance)
	local finalEnd = Config.Map.StartZ + (Config.Map.SectionCount-1)*Config.Map.SectionLength + Config.Map.SectionLength/2
	local finishZ = finalEnd + 20

	local room = Instance.new("Model")
	room.Name = "FinishRoom"
	room.Parent = parent

	safePlatform(room, "FinishBridge", 0, 2.5, finalEnd+6, 24, 12, palette.Green)
	safePlatform(room, "FinishFloor", 0, 2.2, finishZ, 54, 28, palette.Dark)

	arch(room, finishZ-12, palette.Yellow)
	arch(room, finishZ+12, palette.Yellow)

	local finish = safePlatform(room, "Finish", 0, 3.0, finishZ, 30, 14, palette.Yellow)
	finish.Material = Enum.Material.Neon

	sign(room, "YOU ESCAPED HAPPY!", CFrame.new(0,13,finishZ+14)*CFrame.Angles(0,math.pi,0), Vector3.new(30,7,.8), palette.Yellow)
end

local function configureLighting()
	local ok, err = pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
		Lighting.PrioritizeLightingQuality = true
		Lighting.ClockTime = 1.5
		Lighting.Brightness = 2.1
		Lighting.EnvironmentDiffuseScale = .32
		Lighting.EnvironmentSpecularScale = .52
		Lighting.GlobalShadows = true
		Lighting.ShadowSoftness = .3
		Lighting.FogColor = Color3.fromRGB(36,42,60)
		Lighting.FogStart = 95
		Lighting.FogEnd = 980
	end)
	if not ok then
		warn("[MapService] Lighting configuration failed but world remains playable:", err)
	end
end

function MapService.Build()
	if mapModel then
		mapModel:Destroy()
	end

	mapModel = Instance.new("Model")
	mapModel.Name = "GeneratedPlayground"
	mapModel.Parent = Workspace

	buildLobby(mapModel)

	for stageIndex=1,Config.Map.SectionCount do
		local z = Config.Map.StartZ + (stageIndex-1)*Config.Map.SectionLength
		buildSection(mapModel, stageIndex, z)
	end

	buildFinish(mapModel)
	configureLighting()

	mapModel:SetAttribute("BuildComplete", true)
	mapModel:SetAttribute("StageCount", Config.Map.SectionCount)
	print("[MapService] Fair-play course built:", Config.Map.SectionCount, "stages")
	return mapModel
end

function MapService.GetMap()
	return mapModel
end

function MapService.Init(_services)
	-- WorldBootstrap owns initial construction.
end

return MapService
