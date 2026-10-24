--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local CheckpointService = {}
local services
local debounces:{[Player]:number}={}

local function hookCheckpoint(checkpoint: BasePart)
	checkpoint.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		local now=os.clock()
		if debounces[player] and now-debounces[player]<0.5 then return end
		debounces[player]=now
		local index = checkpoint:GetAttribute("CheckpointIndex")
		if type(index) ~= "number" then return end
		local data = services.PlayerDataService.Get(player)
		if not data then return end
		local current=data.Checkpoint or 0
		if index ~= current + 1 then return end
		services.PlayerDataService.Set(player, "Checkpoint", index)
		local ticketReward=math.floor(Config.Game.TicketsPerCheckpoint*services.EntitlementService.TicketMultiplier(player))
		services.PlayerDataService.Add(player, "Tickets", ticketReward)
		services.PlayerDataService.Add(player, "XP", Config.Game.XPPerCheckpoint)
		services.PlayerDataService.Add(player, "TotalCheckpoints", 1)
		services.QuestService.AddStat(player,"Checkpoints",1)
		ReplicatedStorage[Network.FolderName].Checkpoint:FireClient(player, index, ticketReward)
	end)
end

function CheckpointService.Init(allServices)
	services = allServices
	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("CheckpointIndex") then hookCheckpoint(d) end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) debounces[p]=nil end)
end

function CheckpointService.RespawnAtCheckpoint(player: Player)
	local data = services.PlayerDataService.Get(player)
	if not data then return end
	local index = data.Checkpoint or 0
	if index <= 0 then return end
	local map = Workspace:FindFirstChild("GeneratedPlayground")
	if not map then return end
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("CheckpointIndex") == index then
			if player.Character then player.Character:PivotTo(d.CFrame + Vector3.new(0, 4, 0)) end
			return
		end
	end
end

return CheckpointService
