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
local roundId = 0

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
			services.WakeService.Add(Config.Game.BaseWakePerDeath)
			remote(Network.Events.Eliminated):FireClient(player)
			task.delay(2.5, function()
				if player.Parent then
					player:LoadCharacter()
					task.wait(0.5)
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
		if not p.Character then p:LoadCharacter() end
		task.wait()
		teleportToStart(p)
	end
end

function RoundService.BeginFinalChase()
	if not running or finalChase then return end
	finalChase = true
	services.MonsterService.SetActive(true)
	services.MonsterService.SetRage(true)
	remote(Network.Events.Round):FireAllClients({phase = "FINAL", seconds = Config.Game.FinalChaseSeconds})
end

local function runRound()
	roundId += 1
	finalChase = false
	services.WakeService.Reset()
	services.MonsterService.Reset()
	services.MapService.Build()
	resetPlayers()
	running = true

	for remaining = Config.Game.RoundSeconds, 0, -1 do
		remote(Network.Events.Round):FireAllClients({phase = finalChase and "FINAL" or "RUN", seconds = remaining, roundId = roundId})
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
	for _, p in ipairs(Players:GetPlayers()) do
		local data = services.PlayerDataService.Get(p)
		if data and (data.Checkpoint or 0) >= Config.Map.SectionCount then
			services.PlayerDataService.Add(p, "Wins", 1)
			services.PlayerDataService.Add(p, "Tickets", Config.Game.TicketsPerWin)
			remote(Network.Events.Toast):FireClient(p, ("ESCAPED! +%d Tickets"):format(Config.Game.TicketsPerWin))
		end
	end
end

function RoundService.Init(allServices)
	services = allServices
	Players.PlayerAdded:Connect(bindDeaths)
	for _, p in ipairs(Players:GetPlayers()) do bindDeaths(p) end
end

function RoundService.Start()
	while true do
		for remaining = Config.Game.IntermissionSeconds, 0, -1 do
			remote(Network.Events.Round):FireAllClients({phase = "INTERMISSION", seconds = remaining})
			task.wait(1)
		end
		runRound()
	end
end

return RoundService
