--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)
local WakeEvents = require(ReplicatedStorage.Shared.WakeEvents)

local WakeEventService = {}
local services
local running = false
local lastEventAt = 0

local function remote()
	return ReplicatedStorage[Network.FolderName][Network.Events.ServerEvent]
end

local function eligible(wake)
	local list = {}
	for _,event in ipairs(WakeEvents) do
		if wake >= event.MinWake then
			for _=1,event.Weight do table.insert(list,event) end
		end
	end
	return list
end

local function scalePlayers(scale)
	for _,p in ipairs(Players:GetPlayers()) do
		local char=p.Character
		local hum=char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.RigType == Enum.HumanoidRigType.R15 then
			for _,name in ipairs({"BodyDepthScale","BodyHeightScale","BodyWidthScale","HeadScale"}) do
				local v=hum:FindFirstChild(name)
				if v and v:IsA("NumberValue") then v.Value *= scale end
			end
		end
	end
end

local function resetScale(scale)
	if scale == 0 then return end
	scalePlayers(1/scale)
end

local function execute(event)
	remote():FireAllClients({id=event.Id,text=event.Text,duration=event.Duration})
	if event.Id == "lights_out" or event.Id == "blackout_chase" then
		local old=Lighting.Brightness
		Lighting.Brightness=0.15
		task.wait(event.Duration)
		Lighting.Brightness=old
	elseif event.Id == "low_gravity" then
		local old=Workspace.Gravity
		Workspace.Gravity=90
		task.wait(event.Duration)
		Workspace.Gravity=old
	elseif event.Id == "red_alert" then
		local cc=Lighting:FindFirstChild("WakeEventColor") or Instance.new("ColorCorrectionEffect")
		cc.Name="WakeEventColor"; cc.Parent=Lighting
		cc.TintColor=Color3.fromRGB(255,110,110); cc.Contrast=0.25
		task.wait(event.Duration)
		cc.TintColor=Color3.new(1,1,1); cc.Contrast=0
	elseif event.Id == "fog" then
		local old=Lighting.FogEnd
		Lighting.FogEnd=65
		task.wait(event.Duration)
		Lighting.FogEnd=old
	elseif event.Id == "tiny_players" then
		scalePlayers(.68); task.wait(event.Duration); resetScale(.68)
	elseif event.Id == "giant_players" then
		scalePlayers(1.28); task.wait(event.Duration); resetScale(1.28)
	elseif event.Id == "happy_peek" then
		services.MonsterService.SetActive(true)
		services.MonsterService.SetRage(false)
		services.MonsterService.PlaySpecial("WallPeek", math.min(event.Duration, 3.2), true)
		task.wait(event.Duration)
		if services.WakeService.Get() < 60 then
			services.MonsterService.SetActive(false)
		end
	elseif event.Id == "monster_sprint" then
		services.MonsterService.SetActive(true)
		services.MonsterService.PlaySpecial("Roar", 1.1, true)
		task.wait(1.1)
		services.MonsterService.SetRage(true)
		task.wait(math.max(0, event.Duration - 1.1))
		if services.WakeService.Get() < 60 then
			services.MonsterService.SetRage(false)
			services.MonsterService.SetActive(false)
		end
	elseif event.Id == "camera_shake" or event.Id == "platform_pulse" or event.Id == "fake_checkpoint" or event.Id == "reverse_conveyors" or event.Id == "speed_floor" then
		task.wait(event.Duration)
	else
		task.wait(event.Duration)
	end
end

function WakeEventService.Init(allServices) services=allServices end

function WakeEventService.TryRandom()
	if running then return end
	local wake=services.WakeService.Get()
	if wake < Config.Wake.RandomEventMinWake then return end
	if os.clock()-lastEventAt < Config.Wake.EventCooldown then return end
	local pool=eligible(wake)
	if #pool==0 then return end
	local event=pool[math.random(1,#pool)]
	running=true
	lastEventAt=os.clock()
	task.spawn(function()
		local ok,err=pcall(execute,event)
		if not ok then warn("Wake event failed",event.Id,err) end
		running=false
	end)
end

function WakeEventService.Reset()
	running=false
	Workspace.Gravity=196.2
	local c=Lighting:FindFirstChild("WakeEventColor")
	if c and c:IsA("ColorCorrectionEffect") then c.TintColor=Color3.new(1,1,1); c.Contrast=0 end
end

return WakeEventService
