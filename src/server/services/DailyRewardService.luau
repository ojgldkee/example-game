--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local DailyRewardService = {}
local services

local function dayNumber()
	return math.floor(os.time()/86400)
end

function DailyRewardService.Init(allServices)
	services=allServices
end

function DailyRewardService.Claim(player)
	local data=services.PlayerDataService.Get(player)
	if not data then return false,"Loading" end
	data.Daily = data.Daily or {Last=-999999,Streak=0}
	local today=dayNumber()
	if data.Daily.Last == today then return false,"Already claimed" end
	if data.Daily.Last == today-1 then
		data.Daily.Streak = math.min(Config.Progression.DailyStreakCap,(data.Daily.Streak or 0)+1)
	else
		data.Daily.Streak = 1
	end
	data.Daily.Last=today
	local reward=Config.Economy.DailyBaseTickets+(data.Daily.Streak-1)*Config.Economy.DailyStreakBonus
	services.PlayerDataService.Add(player,"Tickets",reward)
	ReplicatedStorage[Network.FolderName].DailyReward:FireClient(player,{reward=reward,streak=data.Daily.Streak})
	return true,reward
end

return DailyRewardService
