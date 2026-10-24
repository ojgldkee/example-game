--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local RoundService = {}
local services
local running = false
local finalChase = false
local roundId = 0\nlocal nextWakeEventAt = 0

local function remote(name: string)
	return ReplicatedStorage:WaitForChild(Network.FolderName):WaitForChild(name)
end

local function teleportToStart(player: Player)
	local map = Workspace:FindFirstChild("GeneratedPlayground")
	local spawn = map and map:FindFirstChild("StartSpawn", true)
	if spawn and spawn:IsA("BasePart") and player.Character then
		player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

local function bindDeaths(player: Player)
	local function hook(character: Model)
		local hum = character:WaitForChild("Humanoid") :: Humanoid
		hum.Died:Connect(function()
			if not running then return end
			services.PlayerDataService.Add(player,"TotalDeaths",1)
			local data=services.PlayerDataService.Get(player)
			local usedRevive=data and (data.Revives or 0)>0
			if usedRevive then
				services.PlayerDataService.Add(player,"Revives",-1)
				remote(Network.Events.Toast):FireClient(player,"REVIVE USED — YOU DIDN'T WAKE HAPPY")
			else
				services.WakeService.Add(Config.Game.BaseWakePerDeath)
				remote(Network.Events.Eliminated):FireClient(player)
			end
			task.delay(usedRevive and 0.75 or Config.Game.RespawnDelay, function()
				if player.Parent then
					player:LoadCharacter()
					task.wait(0.45)
					services.CheckpointService.RespawnAtCheckpoint(player)
				end
			end)
		end)
	end
	player.CharacterAdded:Connect(hook)
	if player.Character then hook(player.Character) end
end

local function resetPlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		services.PlayerDataService.Set(p, "Checkpoint", 0)
		services.QuestService.EnsureDaily(p)
		services.PlayerDataService.Add(p,"RoundsPlayed",1)
		services.QuestService.AddStat(p,"Rounds",1)
		if not p.Character then p:LoadCharacter() end
		task.wait()
		teleportToStart(p)
	end
end

function RoundService.BeginFinalChase()
	if not running or finalChase then return end
	finalChase = true
	services.MonsterService.SetActive(true)
	services.MonsterService.SetFinalChase(true)
	services.MonsterService.PlaySpecial("Roar", 1.2, true)
	remote(Network.Events.Round):FireAllClients({phase = "FINAL", seconds = Config.Game.FinalChaseSeconds, roundId=roundId})
end

local function runRound()
	roundId += 1
	finalChase = false
	services.WakeService.Reset()
	services.WakeEventService.Reset()
	services.MonsterService.Reset()
	services.FinishService.Reset()
	resetPlayers()
	running = true

	for remaining = Config.Game.RoundSeconds, 0, -1 do
		remote(Network.Events.Round):FireAllClients({phase = finalChase and "FINAL" or "RUN", seconds = remaining, roundId = roundId})
		if remaining % 15 == 0 then
			for _,p in ipairs(Players:GetPlayers()) do
				local char=p.Character
				local hum=char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health>0 then services.QuestService.AddStat(p,"SurvivalSeconds",15) end
			end
		end
		if not finalChase and remaining % math.random(Config.Wake.RandomEventIntervalMin,Config.Wake.RandomEventIntervalMax) == 0 then
			services.WakeEventService.TryRandom()
		end
		if finalChase then
			for chase = Config.Game.FinalChaseSeconds, 0, -1 do
				remote(Network.Events.Round):FireAllClients({phase = "FINAL", seconds = chase, roundId = roundId})
				task.wait(1)
			end
			break
		end
		task.wait(1)
	end

	running = false
	services.MonsterService.Reset()
	services.WakeEventService.Reset()
end

function RoundService.IsRunning() return running end
function RoundService.Init(allServices)
	services = allServices
	Players.PlayerAdded:Connect(bindDeaths)
	for _, p in ipairs(Players:GetPlayers()) do bindDeaths(p) end
end

function RoundService.Start()
	while true do
		for remaining = Config.Game.IntermissionSeconds, 0, -1 do
			remote(Network.Events.Round):FireAllClients({phase = "INTERMISSION", seconds = remaining, roundId=roundId})
			task.wait(1)
		end
		runRound()
	end
end

return RoundService
