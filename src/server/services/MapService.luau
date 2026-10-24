--!strict
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapService = {}
local mapModel: Model? = nil

local P = {
	Blue=Color3.fromRGB(27,188,255),
	Pink=Color3.fromRGB(255,70,179),
	Yellow=Color3.fromRGB(255,214,55),
	Green=Color3.fromRGB(64,235,145),
	Purple=Color3.fromRGB(145,82,255),
	Orange=Color3.fromRGB(255,139,55),
	Red=Color3.fromRGB(255,59,82),
	Dark=Color3.fromRGB(26,28,39),
	Dark2=Color3.fromRGB(14,16,23),
	Cream=Color3.fromRGB(248,235,196),
	White=Color3.fromRGB(245,248,255),
	Cyan=Color3.fromRGB(54,236,255),
}

local STAGES = {
	"FIRST STEPS",
	"ZIGZAG DROP",
	"SWEEPER ISLANDS",
	"MOVING CRATES",
	"FALLING FLOOR",
	"BOUNCE HOUSE",
	"CONVEYOR PANIC",
	"LASER HALL",
	"CRUSHER RUN",
	"BLINK BLOCKS",
	"ICE SLALOM",
	"CHOOSE YOUR PAIN",
	"SPIRAL CLIMB",
	"HAPPY'S HALL",
	"FINAL NIGHTMARE",
}

local function part(name:string,size:Vector3,cf:CFrame,color:Color3,parent:Instance,material:Enum.Material?)
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Anchored=true
	p.Color=color
	p.Material=material or Enum.Material.SmoothPlastic
	p.TopSurface=Enum.SurfaceType.Smooth
	p.BottomSurface=Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end

local function platform(parent:Instance,name:string,x:number,y:number,z:number,width:number,depth:number,color:Color3)
	return part(name,Vector3.new(width,1.4,depth),CFrame.new(x,y,z),color,parent,Enum.Material.SmoothPlastic)
end

local function neon(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3)
	local p=part(name,size,cf,color,parent,Enum.Material.Neon)
	p.CanCollide=false
	return p
end

local function surfaceSign(parent:Instance,text:string,cf:CFrame,size:Vector3,color:Color3)
	local board=part("StageSign",size,cf,P.Dark2,parent,Enum.Material.SmoothPlastic)
	board.CanCollide=false
	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Front
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud=36
	gui.Parent=board
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextWrapped=true
	label.Font=Enum.Font.GothamBlack
	label.TextScaled=true
	label.TextColor3=color
	label.Parent=gui
	return board
end

local function damagePart(parent:Instance,name:string,size:Vector3,cf:CFrame,damage:number)
	local p=part(name,size,cf,P.Red,parent,Enum.Material.Neon)
	p.CanCollide=false
	p:SetAttribute("DamagePart",true)
	p:SetAttribute("Damage",damage)
	return p
end

local function stageBounds(centerZ:number):(number,number)
	return centerZ-Config.Map.SectionLength/2,centerZ+Config.Map.SectionLength/2
end

local function hazardDamage(stage:number):number
	if stage<=5 then return Config.Obby.EarlyHazardDamage end
	if stage<=10 then return Config.Obby.MidHazardDamage end
	return Config.Obby.LateHazardDamage
end

local function hazardFloor(parent:Instance,centerZ:number,stage:number)
	local p=part(
		"HazardFloor",
		Vector3.new(Config.Map.CourseWidth-2,1,Config.Map.SectionLength-2),
		CFrame.new(0,Config.Obby.HazardY,centerZ),
		P.Red,
		parent,
		Enum.Material.Neon
	)
	p.Transparency=0.16
	p:SetAttribute("HazardPart",true)
	p:SetAttribute("HazardDamage",hazardDamage(stage))
	return p
end

local function gate(parent:Instance,z:number,color:Color3)
	local opening=20
	local side=(Config.Map.CourseWidth-opening)/2
	part("GateLeft",Vector3.new(side,24,2),CFrame.new(-(opening/2+side/2),12,z),P.Dark,parent)
	part("GateRight",Vector3.new(side,24,2),CFrame.new(opening/2+side/2,12,z),P.Dark,parent)
	part("GateTop",Vector3.new(opening,3,2),CFrame.new(0,22.5,z),color,parent,Enum.Material.Neon)
end

local function roomShell(section:Model,centerZ:number,color:Color3,stage:number)
	local startZ,endZ=stageBounds(centerZ)

	-- Full-width hazard means there is no hidden safe strip down the sides.
	hazardFloor(section,centerZ,stage)

	part("WallL",Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength),CFrame.new(-Config.Map.CourseWidth/2,Config.Map.WallHeight/2,centerZ),P.Dark,section)
	part("WallR",Vector3.new(2,Config.Map.WallHeight,Config.Map.SectionLength),CFrame.new(Config.Map.CourseWidth/2,Config.Map.WallHeight/2,centerZ),P.Dark,section)
	part("Ceiling",Vector3.new(Config.Map.CourseWidth,2,Config.Map.SectionLength),CFrame.new(0,Config.Map.CeilingHeight,centerZ),P.Dark2,section)

	gate(section,startZ+1,color)
	gate(section,endZ-1,color)

	neon(section,"GuideL",Vector3.new(.5,.35,Config.Map.SectionLength-4),CFrame.new(-Config.Map.CourseWidth/2+1.4,1.5,centerZ),color)
	neon(section,"GuideR",Vector3.new(.5,.35,Config.Map.SectionLength-4),CFrame.new(Config.Map.CourseWidth/2-1.4,1.5,centerZ),color)

	for i=-2,2 do
		local light=neon(section,"CeilingLight",Vector3.new(5,.28,1.1),CFrame.new(i*9,Config.Map.CeilingHeight-1.1,centerZ),color)
		light:SetAttribute("WakeLight",true)
	end

	-- Entry and exit islands are the only guaranteed solid ground in every room.
	local entry=platform(section,"StageEntry",0,2.4,startZ+7,20,14,color)
	entry:SetAttribute("SafeIsland",true)

	local checkpoint=platform(section,"Checkpoint",0,2.4,endZ-7,20,14,P.Green)
	checkpoint.CFrame *= CFrame.Angles(0,math.pi,0)
	checkpoint.Material=Enum.Material.Neon
	checkpoint:SetAttribute("CheckpointIndex",stage)
	checkpoint:SetAttribute("SafeIsland",true)

	-- Front face of an unrotated board points toward -Z, exactly where players approach from.
	surfaceSign(
		section,
		("STAGE %02d / %02d   •   %s"):format(stage,Config.Map.SectionCount,STAGES[stage]),
		CFrame.new(0,28,startZ+3.2),
		Vector3.new(24,4.2,.45),
		color
	)
	-- Small directional marker instead of a giant board covering the player's view.
	surfaceSign(
		section,
		">>>",
		CFrame.new(-18,7,startZ+4),
		Vector3.new(5,2.4,.35),
		P.Green
	)
end

local function seriesStart(centerZ:number):number
	local startZ,_=stageBounds(centerZ)
	return startZ+20
end

local function seriesPad(section:Model,name:string,x:number,y:number,z:number,w:number,d:number,color:Color3)
	local p=platform(section,name,x,y,z,w,d,color)
	p:SetAttribute("CoursePlatform",true)
	return p
end

local function spinner(section:Model,z:number,speed:number,radius:number?)
	local r=radius or 10
	platform(section,"SpinnerIsland",0,2.8,z,26,11,P.Cream)
	local bar=damagePart(section,"Spinner",Vector3.new(r*2,1.2,1.5),CFrame.new(0,4.4,z),Config.Obby.LaserDamage)
	bar:SetAttribute("Spinner",true)
	bar:SetAttribute("SpinSpeed",speed)
end

local BUILDERS:{[number]:(Model,number,Color3,number)->()}={}

-- Required edge gap = 3.8 studs. Pads cannot be walked between.
BUILDERS[1]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=6
	local spacing=depth+Config.Movement.BeginnerGap
	local xs={0,-3.5,3.5,-3.5,3.5,-2.5,2.5}
	for i,x in ipairs(xs) do
		seriesPad(section,"FirstStep",x,3.0,z0+(i-1)*spacing,10.5,depth,color)
	end
end

-- Real zig-zag: lateral movement matters, but the longitudinal gap stays 4.4.
BUILDERS[2]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=6
	local spacing=depth+Config.Movement.StandardGap
	local xs={-5.5,5.5,-5.5,5.5,-4,4,-2}
	for i,x in ipairs(xs) do
		local p=seriesPad(section,"Zigzag",x,3.1,z0+(i-1)*spacing,9.5,depth,color)
		p.CFrame*=CFrame.Angles(0,math.rad((i%2==0) and 6 or -6),0)
	end
end

BUILDERS[3]=function(section,centerZ,_color,_stage)
	local z0=seriesStart(centerZ)-1
	local spacing=14.6
	for i=1,5 do
		local z=z0+(i-1)*spacing
		spinner(section,z,24+i*4,9.5)
	end
end

BUILDERS[4]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=7
	local spacing=depth+4.2
	for i=1,6 do
		local x=(i%2==0) and 4.2 or -4.2
		local p=seriesPad(section,"MovingCrate",x,3.2,z0+(i-1)*spacing,11.5,depth,color)
		p:SetAttribute("MoveAxis","X")
		p:SetAttribute("MoveDistance",3.6)
		p:SetAttribute("MoveSpeed",0.72+i*.055)
	end
end

BUILDERS[5]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)-1
	local depth=6
	local spacing=depth+3.5
	local xs={-4,0,4,-4,4,0,-4,4}
	for i,x in ipairs(xs) do
		local p=seriesPad(section,"FallingTile",x,3.0,z0+(i-1)*spacing,10.5,depth,color)
		p:SetAttribute("FallingTile",true)
		p:SetAttribute("FallDelay",0.62)
	end
end

BUILDERS[6]=function(section,centerZ,_color,_stage)
	local z0=seriesStart(centerZ)
	local depth=8
	local spacing=depth+4.1
	for i=1,6 do
		local p=seriesPad(section,"BouncePad",(i%2==0) and 4 or -4,3.0,z0+(i-1)*spacing,12,depth,P.Yellow)
		p.Material=Enum.Material.Neon
		p:SetAttribute("BouncePad",true)
		p:SetAttribute("BounceVelocity",Config.Obby.BounceVelocity)
	end
end

BUILDERS[7]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=7
	local spacing=depth+3.7
	for i=1,7 do
		local p=seriesPad(section,"Conveyor",(i%2==0) and 3.2 or -3.2,3.0,z0+(i-1)*spacing,11.5,depth,color)
		p:SetAttribute("Conveyor",true)
		p:SetAttribute("ConveyorSpeed",(i%3==0) and -6 or 9)
	end
end

-- This room intentionally has a continuous path; the challenge is dodging lasers.
BUILDERS[8]=function(section,centerZ,color,_stage)
	local startZ,endZ=stageBounds(centerZ)
	local floor=platform(section,"LaserRunway",0,2.35,centerZ,22,Config.Map.SectionLength-28,color)
	floor:SetAttribute("SafeIsland",true)
	for i=1,7 do
		local z=startZ+18+(i-1)*9
		if i%2==0 then
			damagePart(section,"Laser",Vector3.new(13,3.8,1),CFrame.new(-5.2,4.5,z),Config.Obby.LaserDamage)
		else
			damagePart(section,"Laser",Vector3.new(13,3.8,1),CFrame.new(5.2,4.5,z),Config.Obby.LaserDamage)
		end
	end
	-- Last laser is low and jumpable.
	damagePart(section,"LowLaser",Vector3.new(20,1.2,1),CFrame.new(0,3.1,endZ-20),Config.Obby.LaserDamage)
end

BUILDERS[9]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=8
	local spacing=depth+4.0
	for i=1,6 do
		local p=seriesPad(section,"CrusherIsland",0,3.0,z0+(i-1)*spacing,18,depth,color)
		p:SetAttribute("SafeIsland",true)
		local crusher=part("Crusher",Vector3.new(8,9,3),CFrame.new((i%2==0) and -17 or 17,6,z0+(i-1)*spacing),P.Red,section,Enum.Material.Neon)
		crusher:SetAttribute("DamagePart",true)
		crusher:SetAttribute("Damage",Config.Obby.LaserDamage)
		crusher:SetAttribute("MoveAxis","X")
		crusher:SetAttribute("MoveDistance",12.5)
		crusher:SetAttribute("MoveSpeed",0.78+i*.04)
	end
end

BUILDERS[10]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=7
	local spacing=depth+4.6
	local xs={-4,4,-4,4,0,-4,4}
	for i,x in ipairs(xs) do
		local p=seriesPad(section,"BlinkBlock",x,3.0,z0+(i-1)*spacing,10.5,depth,color)
		p:SetAttribute("BlinkPlatform",true)
		p:SetAttribute("BlinkPhase",(i-1)*0.22)
	end
end

BUILDERS[11]=function(section,centerZ,color,_stage)
	local startZ,_=stageBounds(centerZ)
	-- Narrow slippery islands: steering challenge rather than raw jump distance.
	for i=1,7 do
		local x=math.sin(i*1.15)*7.5
		local z=startZ+18+(i-1)*10.3
		local p=seriesPad(section,"IceSlalom",x,3.0,z,8.5,6,color)
		p.Material=Enum.Material.Ice
		p.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.03,0.1,1,1)
	end
end

BUILDERS[12]=function(section,centerZ,color,_stage)
	local z0=seriesStart(centerZ)
	local depth=6.5
	local spacing=depth+4.3
	for i=1,7 do
		local z=z0+(i-1)*spacing
		for _,laneX in ipairs({-7,7}) do
			local p=seriesPad(section,"ForkTile",laneX,3.0,z,9.5,depth,color)
			if (i+((laneX>0) and 1 or 0))%3==0 then
				p:SetAttribute("FallingTile",true)
				p:SetAttribute("FallDelay",0.72)
			elseif i%2==0 then
				p:SetAttribute("MoveAxis","X")
				p:SetAttribute("MoveDistance",2.4)
				p:SetAttribute("MoveSpeed",0.65)
			end
		end
	end
end

BUILDERS[13]=function(section,centerZ,color,_stage)
	local startZ,_=stageBounds(centerZ)
	local xs={-5,0,5,7,3,-2,-7,-3}
	for i,x in ipairs(xs) do
		local z=startZ+17+(i-1)*9.25
		local y=3.0+(i-1)*0.65
		seriesPad(section,"SpiralStep",x,y,z,9.5,5.8,color)
	end
end

-- Chase-feeling hall: speed pads plus alternating dodge walls.
BUILDERS[14]=function(section,centerZ,color,_stage)
	local startZ,endZ=stageBounds(centerZ)
	local runway=platform(section,"HappyHallRunway",0,2.35,centerZ,18,Config.Map.SectionLength-28,color)
	runway:SetAttribute("SafeIsland",true)
	for i=1,4 do
		local z=startZ+20+(i-1)*16
		local boost=platform(section,"SpeedPad",0,3.05,z-4,10,5,P.Cyan)
		boost.Material=Enum.Material.Neon
		boost:SetAttribute("SpeedPad",true)
		boost:SetAttribute("SpeedBoost",Config.Obby.SpeedPadBoost)
		local wallX=(i%2==0) and 5.5 or -5.5
		damagePart(section,"DodgeWall",Vector3.new(9,7,2),CFrame.new(wallX,5.6,z+3),Config.Obby.LaserDamage)
	end
	damagePart(section,"FinishLaser",Vector3.new(18,1.2,1),CFrame.new(0,3.1,endZ-18),Config.Obby.LaserDamage)
end

BUILDERS[15]=function(section,centerZ,color,_stage)
	local startZ,_=stageBounds(centerZ)
	local specs={
		{x=0,z=18,w=11,d=6,kind="normal"},
		{x=-4,z=29,w=10,d=6,kind="moving"},
		{x=4,z=40,w=10,d=6,kind="blink"},
		{x=0,z=51,w=18,d=10,kind="spinner"},
		{x=-4,z=65,w=10,d=6,kind="fall"},
		{x=4,z=76,w=10,d=6,kind="normal"},
	}
	for i,s in ipairs(specs) do
		local z=startZ+s.z
		local p=seriesPad(section,"FinalPlatform",s.x,3.1,z,s.w,s.d,color)
		if s.kind=="moving" then
			p:SetAttribute("MoveAxis","X")
			p:SetAttribute("MoveDistance",3.4)
			p:SetAttribute("MoveSpeed",0.95)
		elseif s.kind=="blink" then
			p:SetAttribute("BlinkPlatform",true)
			p:SetAttribute("BlinkPhase",0.4)
		elseif s.kind=="fall" then
			p:SetAttribute("FallingTile",true)
			p:SetAttribute("FallDelay",0.55)
		elseif s.kind=="spinner" then
			spinner(section,z,38,8)
		end
	end
end

local function buildSection(parent:Model,stage:number,centerZ:number)
	local section=Instance.new("Model")
	section.Name=("Stage_%02d_%s"):format(stage,string.gsub(STAGES[stage]," ","_"))
	section:SetAttribute("StageIndex",stage)
	section:SetAttribute("StageName",STAGES[stage])
	section.Parent=parent

	local colors={P.Blue,P.Pink,P.Yellow,P.Green,P.Purple,P.Orange}
	local color=colors[((stage-1)%#colors)+1]

	roomShell(section,centerZ,color,stage)
	BUILDERS[stage](section,centerZ,color,stage)
end

local function buildLobby(parent:Model)
	local firstCenter=Config.Map.StartZ
	local firstStart,_=stageBounds(firstCenter)
	local centerZ=firstStart-Config.Map.LobbyLength/2

	local lobby=Instance.new("Model")
	lobby.Name="Lobby"
	lobby.Parent=parent

	part("LobbyFloor",Vector3.new(70,2,Config.Map.LobbyLength),CFrame.new(0,0,centerZ),P.Dark,lobby,Enum.Material.Rubber)
	part("LobbyBack",Vector3.new(70,30,2),CFrame.new(0,15,centerZ-Config.Map.LobbyLength/2),P.Dark2,lobby)

	surfaceSign(lobby,"HAPPY'S PLAYPLACE\n15 STAGES. ONE EXIT.",CFrame.new(0,17,centerZ-Config.Map.LobbyLength/2+1),Vector3.new(38,9,.7),P.Yellow)
	surfaceSign(lobby,"FOLLOW THE GLOWING GATES\nTHE COURSE ALWAYS MOVES FORWARD",CFrame.new(0,8,centerZ-Config.Map.LobbyLength/2+1.1),Vector3.new(42,5,.7),P.Cyan)

	local spawn=Instance.new("SpawnLocation")
	spawn.Name="StartSpawn"
	spawn.Size=Vector3.new(18,1,14)
	spawn.CFrame=CFrame.new(0,3,firstStart-14)*CFrame.Angles(0,math.pi,0)
	spawn.Anchored=true
	spawn.Neutral=true
	spawn.Material=Enum.Material.Neon
	spawn.Color=P.Green
	spawn.Parent=lobby

	platform(lobby,"StartBridge",0,2.3,firstStart-5,20,18,P.Green)
	surfaceSign(lobby,"GO  >>>",CFrame.new(0,6.5,firstStart-3.5),Vector3.new(13,3,.5),P.Green)
end

local function buildFinish(parent:Model)
	local finalCenter=Config.Map.StartZ+(Config.Map.SectionCount-1)*Config.Map.SectionLength
	local _,finalEnd=stageBounds(finalCenter)
	local z=finalEnd+20

	local finish=Instance.new("Model")
	finish.Name="FinishRoom"
	finish.Parent=parent

	platform(finish,"FinishBridge",0,2.4,finalEnd+6,20,12,P.Green)
	platform(finish,"FinishFloor",0,2.2,z,48,28,P.Dark)

	local pad=platform(finish,"Finish",0,3.0,z,26,12,P.Yellow)
	pad.Material=Enum.Material.Neon

	surfaceSign(finish,"ESCAPED!\nCLAIM YOUR WIN",CFrame.new(0,12,z+13),Vector3.new(28,7,.6),P.Yellow)
end

local function configureLighting()
	local ok,err=pcall(function()
		Lighting.LightingStyle=Enum.LightingStyle.Realistic
		Lighting.PrioritizeLightingQuality=true
		Lighting.ClockTime=0.8
		Lighting.Brightness=1.9
		Lighting.EnvironmentDiffuseScale=.28
		Lighting.EnvironmentSpecularScale=.5
		Lighting.GlobalShadows=true
		Lighting.ShadowSoftness=.32
		Lighting.FogColor=Color3.fromRGB(28,34,52)
		Lighting.FogStart=110
		Lighting.FogEnd=1150
	end)
	if not ok then
		warn("[MapService] Lighting setup failed:",err)
	end
end

function MapService.Build()
	if mapModel then mapModel:Destroy() end

	mapModel=Instance.new("Model")
	mapModel.Name="GeneratedPlayground"
	mapModel.Parent=Workspace

	buildLobby(mapModel)
	for stage=1,Config.Map.SectionCount do
		local centerZ=Config.Map.StartZ+(stage-1)*Config.Map.SectionLength
		buildSection(mapModel,stage,centerZ)
	end
	buildFinish(mapModel)
	configureLighting()

	mapModel:SetAttribute("BuildComplete",true)
	mapModel:SetAttribute("StageCount",Config.Map.SectionCount)
	mapModel:SetAttribute("CourseDirection","PositiveZ")
	print("[MapService] Built authored 15-stage course with no side shortcuts")
	return mapModel
end

function MapService.GetMap()
	return mapModel
end

function MapService.Init(_services)
	-- WorldBootstrap owns construction.
end

return MapService
