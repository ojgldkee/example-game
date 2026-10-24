--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local FinishService = {}
local services
local finished: {[Player]: boolean} = {}

function FinishService.Init(allServices)
	services = allServices
	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")
		local finish = map:WaitForChild("Finish") :: BasePart
		finish.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or finished[player] then return end
			local data = services.PlayerDataService.Get(player)
			if not data or (data.Checkpoint or 0) < Config.Map.SectionCount then return end
			finished[player] = true
			services.PlayerDataService.Add(player, "Wins", 1)
			services.PlayerDataService.Add(player, "Tickets", Config.Game.TicketsPerWin)
			ReplicatedStorage[Network.FolderName].Toast:FireClient(player, ("YOU ESCAPED! +%d TICKETS"):format(Config.Game.TicketsPerWin))
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		finished[player] = nil
	end)
end

function FinishService.Reset()
	finished = {}
end

return FinishService
