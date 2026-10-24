--!strict
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)

local MapService={}
local mapModel:Model?=nil

local palette={
	Blue=Color3.fromRGB(31,186,255), Pink=Color3.fromRGB(255,80,184),
	Yellow=Color3.fromRGB(255,218,67), Green=Color3.fromRGB(79,238,150),
	Purple=Color3.fromRGB(150,93,255), Orange=Color3.fromRGB(255,143,62),
	Dark=Color3.fromRGB(30,32,43), Dark2=Color3.fromRGB(20,22,30),
	Cream=Color3.fromRGB(247,236,201), Red=Color3.fromRGB(255,73,73),
}

local function part(name,size,cf,color,parent,material)
	local p=Instance.new("Part")
	p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true
	p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end

local function neon(name,size,cf,color,parent)
	local p=part(name,size,cf,color,parent,Enum.Material.Neon)
	p.CanCollide=false
	return p
end

local function textSign(parent,text,cf,size,color)
	local board=part("Sign",size,cf,palette.Dark2,parent)
	local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=40; gui.Parent=board
	local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=text; label.Font=Enum.Font.GothamBlack; label.TextScaled=true; label.TextColor3=color; label.Parent=gui
	return board
end

local function arch(parent,z,color)
	part("ArchL",Vector3.new(3,20,4),CFrame.new(-Config.Map.CourseWidth/2+2,10,z),color,parent)
	part("ArchR",Vector3.new(3,20,4),CFrame.new(Config.Map.CourseWidth/2-2,10,z),color,parent)
	part("ArchTop",Vector3.new(Config.Map.CourseWidth,3,4),CFrame.new(0,20,z),color,parent)
end

local function buildShell(section,z,color)
	part("Floor",Vector3.new(Config.Map.CourseWidth,2,Config.Map.SectionLength),CFrame.new(0,0,z),palette.Dark,section,Enum.Material.Rubber)
	part("WallL",Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength),CFrame.new(-Config.Map.CourseWidth/2,Config.Map.WallHeight/2,z),Color3.fromRGB(36,40,54),section)
	part("WallR",Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength),CFrame.new(Config.Map.CourseWidth/2,Config.Map.WallHeight/2,z),Color3.fromRGB(36,40,54),section)
	part("Ceiling",Vector3.new(Config.Map.CourseWidth,2,Config.Map.SectionLength),CFrame.new(0,Config.Map.CeilingHeight,z),Color3.fromRGB(22,24,33),section)
	neon("RailL",Vector3.new(.7,.4,Config.Map.SectionLength),CFrame.new(-Config.Map.CourseWidth/2+1.6,2,z),color,section)
	neon("RailR",Vector3.new(.7,.4,Config.Map.SectionLength),CFrame.new(Config.Map.CourseWidth/2-1.6,2,z),color,section)
	for i=-2,2 do
		local lamp=neon("CeilingLight",Vector3.new(5,.35,1.3),CFrame.new(i*9,Config.Map.CeilingHeight-1.2,z),color,section)
		lamp:SetAttribute("WakeLight",true)
	end
	arch(section,z-Config.Map.SectionLength/2+3,color)
	arch(section,z+Config.Map.SectionLength/2-3,color)
end

local function hazardZone(parent,z)
	local kill=part("Void",Vector3.new(Config.Map.CourseWidth-8,.5,48),CFrame.new(0,1.1,z),Color3.fromRGB(255,52,86),parent,Enum.Material.Neon)
	kill.Transparency=.25
	kill:SetAttribute("KillPart",true)
end

local builders={}

builders[1]=function(section,z,color)
	hazardZone(section,z)
	for i=1,7 do
		local x=(i%2==0) and 9 or -9
		part("JumpPad",Vector3.new(10,1.5,7),CFrame.new(x,3+(i%3)*1.2,z-27+i*8),color,section)
	end
end

builders[2]=function(section,z,color)
	hazardZone(section,z)
	for i=1,6 do
		local x=((i%3)-1)*11
		part("Beam",Vector3.new(4,1.4,11),CFrame.new(x,3+i*.6,z-29+i*9)*CFrame.Angles(0,math.rad(i*13),0),color,section)
	end
end

builders[3]=function(section,z,color)
	hazardZone(section,z)
	for i=1,5 do
		local p=part("MovingPlatform",Vector3.new(9,1.5,9),CFrame.new(i%2==0 and 11 or -11,4,z-27+i*11),color,section)
		p:SetAttribute("MoveAxis",i%2==0 and "X" or "Y")
		p:SetAttribute("MoveDistance",8+i*1.7); p:SetAttribute("MoveSpeed",1+i*.18)
	end
end

builders[4]=function(section,z,color)
	hazardZone(section,z)
	for i=1,9 do
		local p=part("FallingTile",Vector3.new(7.5,1,6),CFrame.new(((i%3)-1)*9,3,z-29+i*6.4),color,section)
		p:SetAttribute("FallingTile",true)
	end
end

builders[5]=function(section,z,color)
	for i=1,5 do
		local pole=part("SpinnerPole",Vector3.new(2,8,2),CFrame.new(0,4,z-24+i*10),palette.Cream,section)
		local bar=part("Spinner",Vector3.new(30,1,2),pole.CFrame*CFrame.new(0,2,0),palette.Yellow,section,Enum.Material.Neon)
		bar:SetAttribute("Spinner",true); bar:SetAttribute("SpinSpeed",38+i*8)
	end
end

builders[6]=function(section,z,color)
	hazardZone(section,z)
	for i=1,6 do
		local width=math.max(4,12-i)
		part("NarrowingPad",Vector3.new(width,1.2,8),CFrame.new((i%2==0 and 10 or -10),3+i*.7,z-27+i*9),color,section)
	end
end

local function buildSection(parent,index,z)
	local section=Instance.new("Model"); section.Name=("Section_%02d"):format(index); section.Parent=parent
	local colors={palette.Blue,palette.Pink,palette.Yellow,palette.Green,palette.Purple,palette.Orange}
	local color=colors[((index-1)%#colors)+1]
	buildShell(section,z,color)
	local builder=builders[((index-1)%#builders)+1]
	builder(section,z,color)
	local cp=part("Checkpoint",Vector3.new(14,1,5),CFrame.new(0,2,z+Config.Map.SectionLength/2-8),palette.Green,section,Enum.Material.Neon)
	cp:SetAttribute("CheckpointIndex",index)
	textSign(section,("ZONE %02d"):format(index),CFrame.new(0,12,z-Config.Map.SectionLength/2+5)*CFrame.Angles(0,math.pi,0),Vector3.new(16,5,.7),color)
end

local function buildLobby(parent)
	local z=Config.Map.StartZ-Config.Map.LobbyLength
	local lobby=Instance.new("Model"); lobby.Name="Lobby"; lobby.Parent=parent
	part("LobbyFloor",Vector3.new(76,2,Config.Map.LobbyLength),CFrame.new(0,0,z),Color3.fromRGB(42,45,60),lobby,Enum.Material.Rubber)
	part("BackWall",Vector3.new(76,28,2),CFrame.new(0,14,z-Config.Map.LobbyLength/2),palette.Dark2,lobby)
	for _,x in ipairs({-28,-14,0,14,28}) do
		neon("LobbyStrip",Vector3.new(6,.4,1),CFrame.new(x,25,z-Config.Map.LobbyLength/2+1.1),x%28==0 and palette.Blue or palette.Pink,lobby)
	end
	textSign(lobby,"HAPPY'S PLAYPLACE",CFrame.new(0,16,z-Config.Map.LobbyLength/2+1.2),Vector3.new(42,8,.8),palette.Yellow)
	textSign(lobby,"EVERY DEATH WAKES IT UP",CFrame.new(0,8,z-Config.Map.LobbyLength/2+1.3),Vector3.new(34,4,.8),palette.Red)
	local spawn=Instance.new("SpawnLocation"); spawn.Name="StartSpawn"; spawn.Size=Vector3.new(16,1,16); spawn.CFrame=CFrame.new(0,3,z+12); spawn.Anchored=true; spawn.Neutral=true; spawn.Color=palette.Green; spawn.Material=Enum.Material.Neon; spawn.Parent=lobby
	for i=-2,2 do
		local seat=part("Bench",Vector3.new(8,2,3),CFrame.new(i*13,2,z-4),i%2==0 and palette.Blue or palette.Pink,lobby)
		seat:SetAttribute("Decor",true)
	end
end

local function buildFinish(parent)
	local z=Config.Map.StartZ+Config.Map.SectionCount*Config.Map.SectionLength
	local finishRoom=Instance.new("Model"); finishRoom.Name="FinishRoom"; finishRoom.Parent=parent
	part("FinishFloor",Vector3.new(70,2,42),CFrame.new(0,0,z),palette.Dark,finishRoom)
	arch(finishRoom,z-14,palette.Yellow); arch(finishRoom,z+14,palette.Yellow)
	local finish=part("Finish",Vector3.new(28,1.4,14),CFrame.new(0,2,z),palette.Yellow,finishRoom,Enum.Material.Neon)
	textSign(finishRoom,"ESCAPE",CFrame.new(0,13,z+15)*CFrame.Angles(0,math.pi,0),Vector3.new(24,7,.8),palette.Yellow)
end

local function configureLighting()
	-- Lighting APIs evolve. Never let a visual setting prevent the world from loading.
	local ok, err = pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
		Lighting.PrioritizeLightingQuality = true
		Lighting.ClockTime = 1.5
		Lighting.Brightness = 2.2
		Lighting.EnvironmentDiffuseScale = .35
		Lighting.EnvironmentSpecularScale = .55
		Lighting.GlobalShadows = true
		Lighting.ShadowSoftness = .28
		Lighting.FogColor = Color3.fromRGB(36,42,60)
		Lighting.FogStart = 75
		Lighting.FogEnd = 900
	end)
	if not ok then
		warn("[MapService] Lighting configuration failed but map will continue:", err)
	end
end

function MapService.Build()
	if mapModel then mapModel:Destroy() end
	mapModel=Instance.new("Model")
	mapModel.Name="GeneratedPlayground"
	mapModel.Parent=Workspace

	-- Build playable geometry BEFORE any nonessential visual configuration.
	buildLobby(mapModel)
	for i=1,Config.Map.SectionCount do
		buildSection(mapModel,i,Config.Map.StartZ+(i-1)*Config.Map.SectionLength)
	end
	buildFinish(mapModel)
	configureLighting()
	mapModel:SetAttribute("BuildComplete", true)
	print("[MapService] GeneratedPlayground built with", Config.Map.SectionCount, "sections")
	return mapModel
end

function MapService.GetMap() return mapModel end
function MapService.Init(_services)\n\t-- WorldBootstrap.server.luau owns initial world construction so map boot is isolated\n\t-- from progression/monetization/round-service failures.\nend
return MapService
