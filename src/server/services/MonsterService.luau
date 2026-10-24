--!strict
local Players=game:GetService("Players")
local PathfindingService=game:GetService("PathfindingService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Config=require(ReplicatedStorage.Shared.Config)
local Network=require(ReplicatedStorage.Shared.Network)

local MonsterService={}
local model:Model?=nil
local humanoid:Humanoid?=nil
local animator:Animator?=nil
local tracks={}
local active=false
local rage=false
local services

local function loadTrack(name,id,priority,looped)
	if id==0 or not animator then return end
	local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://"..id
	local track=animator:LoadAnimation(anim); track.Priority=priority; track.Looped=looped; tracks[name]=track
end

local function play(name)
	for n,t in pairs(tracks) do if n~=name and t.IsPlaying then t:Stop(.18) end end
	local t=tracks[name]; if t and not t.IsPlaying then t:Play(.18) end
end

local function createFallback()
	local m=Instance.new("Model"); m.Name=Config.Monster.Name
	local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(3,5,2); root.Transparency=1; root.Anchored=false; root.CanCollide=true; root.Parent=m
	local torso=Instance.new("Part"); torso.Name="TorsoVisual"; torso.Size=Vector3.new(4.4,6,3); torso.Color=Color3.fromRGB(32,170,230); torso.Parent=m
	local head=Instance.new("Part"); head.Name="Head"; head.Shape=Enum.PartType.Ball; head.Size=Vector3.new(5,5,5); head.Color=Color3.fromRGB(247,225,154); head.Parent=m
	torso.CFrame=root.CFrame; head.CFrame=root.CFrame*CFrame.new(0,5,0)
	for _,p in ipairs({torso,head}) do local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=root end
	local hum=Instance.new("Humanoid"); hum.Name="Humanoid"; hum.AutoRotate=true; hum.WalkSpeed=Config.Monster.BaseSpeed; hum.Parent=m
	local an=Instance.new("Animator"); an.Parent=hum
	m.PrimaryPart=root; m.Parent=Workspace; m:PivotTo(CFrame.new(0,-100,0))
	return m,hum,an
end

local function createMonster()
	if model then model:Destroy() end
	local imported=ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild(Config.Monster.Name)
	if imported and imported:IsA("Model") then
		model=imported:Clone(); model.Parent=Workspace
		humanoid=model:FindFirstChildOfClass("Humanoid")
		if not humanoid then humanoid=Instance.new("Humanoid"); humanoid.Parent=model end
		animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",humanoid)
	else
		model,humanoid,animator=createFallback()
	end
	if model and not model.PrimaryPart then model.PrimaryPart=model:FindFirstChild("HumanoidRootPart") :: BasePart end
	if model then model:PivotTo(CFrame.new(0,-100,0)) end
	loadTrack("Idle",Config.AnimationIds.HappyIdle,Enum.AnimationPriority.Idle,true)
	loadTrack("Walk",Config.AnimationIds.HappyWalk,Enum.AnimationPriority.Movement,true)
	loadTrack("Run",Config.AnimationIds.HappyRun,Enum.AnimationPriority.Movement,true)
	loadTrack("Crawl",Config.AnimationIds.HappyCrawl,Enum.AnimationPriority.Action,true)
	loadTrack("Lunge",Config.AnimationIds.HappyLunge,Enum.AnimationPriority.Action,false)\n\tloadTrack("Roar",Config.AnimationIds.HappyRoar,Enum.AnimationPriority.Action,false)\n\tloadTrack("WallPeek",Config.AnimationIds.HappyWallPeek,Enum.AnimationPriority.Action,false)\n\tloadTrack("CeilingCrawl",Config.AnimationIds.HappyCeilingCrawl,Enum.AnimationPriority.Action,true)\n\tloadTrack("Jumpscare",Config.AnimationIds.HappyJumpscare,Enum.AnimationPriority.Action,false)
end

local function nearest()
	if not model or not model.PrimaryPart then return nil end
	local best,bestDist=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		local c=p.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
		if hrp and h and h.Health>0 then
			local d=(hrp.Position-model.PrimaryPart.Position).Magnitude
			if d<bestDist then best=p; bestDist=d end
		end
	end
	return best
end

local function spawnBehind()
	if not model then createMonster() end
	local map=Workspace:FindFirstChild("GeneratedPlayground")
	local spawn=map and map:FindFirstChild("StartSpawn",true)
	if model and spawn and spawn:IsA("BasePart") then model:PivotTo(spawn.CFrame*CFrame.new(0,4,Config.Monster.SpawnDistanceBehind)) end
end

local function attack(target)
	local char=target.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	play("Lunge")
	ReplicatedStorage[Network.FolderName].MonsterEvent:FireClient(target,{type="jumpscare"})
	task.wait(.22)
	if hum.Health>0 then hum.Health=0 end
end

local function chaseLoop()
	while true do
		if active and model and humanoid and model.PrimaryPart then
			humanoid.WalkSpeed=rage and Config.Monster.FinalSpeed or Config.Monster.AwakeSpeed
			play(rage and "Run" or "Walk")
			local target=nearest(); local char=target and target.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
			if target and hrp and hrp:IsA("BasePart") then
				if (hrp.Position-model.PrimaryPart.Position).Magnitude<=Config.Monster.AttackDistance then attack(target) end
				local path=PathfindingService:CreatePath({AgentRadius=2.8,AgentHeight=8,AgentCanJump=true,WaypointSpacing=8})
				local ok=pcall(function() path:ComputeAsync(model.PrimaryPart.Position,hrp.Position) end)
				if ok and path.Status==Enum.PathStatus.Success then
					local points=path:GetWaypoints()
					for i=2,math.min(#points,4) do
						if not active then break end
						if points[i].Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
						humanoid:MoveTo(points[i].Position)
						local reached=humanoid.MoveToFinished:Wait()
						if not reached then break end
						if model.PrimaryPart and (hrp.Position-model.PrimaryPart.Position).Magnitude<=Config.Monster.AttackDistance then attack(target); break end
					end
				else humanoid:MoveTo(hrp.Position) end
			end
		else play("Idle") end
		task.wait(Config.Monster.RepathSeconds)
	end
end

function MonsterService.Init(allServices) services=allServices; createMonster(); task.spawn(chaseLoop) end
function MonsterService.SetActive(v) active=v; if v then spawnBehind() elseif model then model:PivotTo(CFrame.new(0,-100,0)) end end
function MonsterService.SetRage(v) rage=v end\n\nfunction MonsterService.PlaySpecial(name:string)\n\tif name=="Roar" then play("Roar")\n\telseif name=="WallPeek" then play("WallPeek")\n\telseif name=="CeilingCrawl" then play("CeilingCrawl")\n\telseif name=="Jumpscare" then play("Jumpscare")\n\tend\nend
function MonsterService.Reset() active=false; rage=false; if model then model:PivotTo(CFrame.new(0,-100,0)) end end
return MonsterService
