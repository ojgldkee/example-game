--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local CheckpointService = {}
local services

local function hookCheckpoint(checkpoint: BasePart)
	checkpoint.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		local index = checkpoint:GetAttribute("CheckpointIndex")
		if type(index) ~= "number" then return end
		local data = services.PlayerDataService.Get(player)
		if not data then return end
		if index > (data.Checkpoint or 0) then
			services.PlayerDataService.Set(player, "Checkpoint", index)
			services.PlayerDataService.Add(player, "Tickets", Config.Game.TicketsPerCheckpoint)
			ReplicatedStorage[Network.FolderName].Checkpoint:FireClient(player, index, Config.Game.TicketsPerCheckpoint)
		end
	end)
end

function CheckpointService.Init(allServices)
	services = allServices
	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("CheckpointIndex") then
				hookCheckpoint(d)
			end
		end
	end)
end

function CheckpointService.RespawnAtCheckpoint(player: Player)
	local data = services.PlayerDataService.Get(player)
	if not data then return end
	local index = data.Checkpoint or 0
	if index <= 0 then return end
	local map = Workspace:FindFirstChild("GeneratedPlayground")
	if not map then return end
	local checkpoint = map:FindFirstChild("Checkpoint", true)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("CheckpointIndex") == index then
			checkpoint = d
			break
		end
	end
	if checkpoint and player.Character then
		player.Character:PivotTo(checkpoint.CFrame + Vector3.new(0, 4, 0))
	end
end

return CheckpointService
