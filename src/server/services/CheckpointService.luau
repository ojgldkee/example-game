--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local CheckpointService = {}
local services
local debounces: {[Player]: number} = {}

local function ensureLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local stage = leaderstats:FindFirstChild("Stage")
	if not stage then
		stage = Instance.new("IntValue")
		stage.Name = "Stage"
		stage.Value = 0
		stage.Parent = leaderstats
	end
	return stage :: IntValue
end

local function setVisibleStage(player: Player, value: number)
	ensureLeaderstats(player).Value = value
end

local function hookCheckpoint(checkpoint: BasePart)
	checkpoint.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local now = os.clock()
		if debounces[player] and now - debounces[player] < 0.5 then return end
		debounces[player] = now

		local index = checkpoint:GetAttribute("CheckpointIndex")
		if type(index) ~= "number" then return end

		local data = services.PlayerDataService.Get(player)
		if not data then return end

		local current = data.Checkpoint or 0
		if index ~= current + 1 then return end

		services.PlayerDataService.Set(player,"Checkpoint",index)

		local ticketReward = math.floor(
			Config.Game.TicketsPerCheckpoint * services.EntitlementService.TicketMultiplier(player)
		)

		services.PlayerDataService.Add(player,"Tickets",ticketReward)
		services.PlayerDataService.Add(player,"XP",Config.Game.XPPerCheckpoint)
		services.PlayerDataService.Add(player,"TotalCheckpoints",1)
		services.QuestService.AddStat(player,"Checkpoints",1)

		setVisibleStage(player,index)
		ReplicatedStorage[Network.FolderName].Checkpoint:FireClient(player,index,ticketReward)
	end)
end

function CheckpointService.Init(allServices)
	services = allServices

	Players.PlayerAdded:Connect(function(player)
		ensureLeaderstats(player)
	end)

	for _,player in ipairs(Players:GetPlayers()) do
		ensureLeaderstats(player)
	end

	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")
		for _, descendant in ipairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("CheckpointIndex") then
				hookCheckpoint(descendant)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		debounces[player] = nil
	end)
end

function CheckpointService.ResetPlayerStage(player: Player)
	setVisibleStage(player,0)
end

function CheckpointService.RespawnAtCheckpoint(player: Player)
	local data = services.PlayerDataService.Get(player)
	if not data then return end

	local index = data.Checkpoint or 0
	if index <= 0 then return end

	local map = Workspace:FindFirstChild("GeneratedPlayground")
	if not map then return end

	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("CheckpointIndex") == index then
			if player.Character then
				player.Character:PivotTo(descendant.CFrame + Vector3.new(0,Config.Obby.CheckpointLift,0))
			end
			return
		end
	end
end

return CheckpointService
