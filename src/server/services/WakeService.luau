--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local WakeService = {}
local wake = 0
local services
local triggered: {[number]: boolean} = {}

local function fireState()
	local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)
	remotes.State:FireAllClients({wake = wake})
	remotes.WakePulse:FireAllClients(wake)
	for _,p in ipairs(Players:GetPlayers()) do
		services.QuestService.AddStat(p,"WakeSeen",wake)
	end
end

local function applyEnvironment()
	local t = wake / 100
	Lighting.Brightness = 2.2 - 1.35 * t
	Lighting.FogEnd = 900 - 670 * t
	Lighting.Ambient = Color3.fromRGB(105 - math.floor(60*t), 105 - math.floor(70*t), 125 - math.floor(70*t))
	Lighting.OutdoorAmbient = Lighting.Ambient
end

local function triggerThreshold(threshold: number)
	if triggered[threshold] then return end
	triggered[threshold] = true
	local toast=ReplicatedStorage[Network.FolderName].Toast
	if threshold == 10 then toast:FireAllClients("The playground noticed you.")
	elseif threshold == 20 then toast:FireAllClients("The lights are starting to flicker...")
	elseif threshold == 35 then toast:FireAllClients("The walls are moving.")
	elseif threshold == 50 then toast:FireAllClients("Half awake. Don't stop.")
	elseif threshold == 65 then
		toast:FireAllClients("Happy is awake.")
		services.MonsterService.SetActive(true)
	elseif threshold == 80 then
		toast:FireAllClients("RUN. It knows where you are.")
		services.MonsterService.SetRage(true)
	elseif threshold == 90 then
		toast:FireAllClients("IT'S RIGHT BEHIND YOU.")
		services.MonsterService.SetRage(true)
	elseif threshold == 100 then
		toast:FireAllClients("100% AWAKE — FINAL CHASE")
		services.RoundService.BeginFinalChase()
	end
	services.WakeEventService.TryRandom()
end

function WakeService.Init(allServices) services = allServices end

function WakeService.Reset()
	wake = 0
	triggered = {}
	applyEnvironment()
	fireState()
end

function WakeService.Add(amount: number)
	local old = wake
	wake = math.clamp(wake + amount, 0, Config.Game.MaxWake)
	applyEnvironment()
	for _, threshold in ipairs(Config.Wake.Thresholds) do
		if old < threshold and wake >= threshold then triggerThreshold(threshold) end
	end
	fireState()
end

function WakeService.Get() return wake end
return WakeService
