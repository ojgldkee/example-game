--!strict
local Lighting = game:GetService("Lighting")
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
end

local function applyEnvironment()
	local t = wake / 100
	Lighting.Brightness = 2 - 1.1 * t
	Lighting.FogEnd = 1000 - 650 * t
	Lighting.Ambient = Color3.fromRGB(90 - math.floor(45*t), 90 - math.floor(55*t), 110 - math.floor(60*t))
	Lighting.OutdoorAmbient = Lighting.Ambient
end

local function triggerThreshold(threshold: number)
	if triggered[threshold] then return end
	triggered[threshold] = true
	if threshold == 20 then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients("The lights are starting to flicker...")
	elseif threshold == 40 then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients("Something is moving behind the walls.")
	elseif threshold == 60 then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients("Happy is awake.")
		if services.MonsterService then services.MonsterService.SetActive(true) end
	elseif threshold == 80 then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients("RUN. It knows where you are.")
		if services.MonsterService then services.MonsterService.SetRage(true) end
	elseif threshold == 100 then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients("100% AWAKE — FINAL CHASE")
		if services.RoundService then services.RoundService.BeginFinalChase() end
	end
end

function WakeService.Init(allServices)
	services = allServices
end

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
	for _, threshold in ipairs(Config.WakeThresholds) do
		if old < threshold and wake >= threshold then
			triggerThreshold(threshold)
		end
	end
	fireState()
end

function WakeService.Get()
	return wake
end

return WakeService
