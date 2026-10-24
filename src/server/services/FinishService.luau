--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Config=require(ReplicatedStorage.Shared.Config)
local Network=require(ReplicatedStorage.Shared.Network)

local FinishService={}
local services
local finished:{[Player]:boolean}={}

function FinishService.Init(allServices)
	services=allServices
	task.defer(function()
		local map=Workspace:WaitForChild("GeneratedPlayground")
		local finish=map:FindFirstChild("Finish",true)
		if not finish or not finish:IsA("BasePart") then error("Finish part missing") end
		finish.Touched:Connect(function(hit)
			local player=Players:GetPlayerFromCharacter(hit.Parent)
			if not player or finished[player] then return end
			local data=services.PlayerDataService.Get(player)
			if not data or (data.Checkpoint or 0)<Config.Map.SectionCount then return end
			finished[player]=true
			services.PlayerDataService.Add(player,"Wins",1)
			local ticketReward=math.floor(Config.Game.TicketsPerWin*services.EntitlementService.TicketMultiplier(player))
			services.PlayerDataService.Add(player,"Tickets",ticketReward)
			services.PlayerDataService.Add(player,"XP",Config.Game.XPPerWin)
			services.QuestService.AddStat(player,"Wins",1)
			data.BestWakeEscaped=math.max(data.BestWakeEscaped or 0,services.WakeService.Get())
			services.PlayerDataService.MarkDirty(player)
			ReplicatedStorage[Network.FolderName].Toast:FireClient(player,("ESCAPED! +%d TICKETS"):format(ticketReward))
		end)
	end)
	Players.PlayerRemoving:Connect(function(p) finished[p]=nil end)
end

function FinishService.Reset() finished={} end
return FinishService
