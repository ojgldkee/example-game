--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Quests = require(ReplicatedStorage.Shared.Quests)
local Network = require(ReplicatedStorage.Shared.Network)

local QuestService = {}
local services

local function ensure(player)
	local data = services.PlayerDataService.Get(player)
	if not data then return nil end
	data.QuestState = data.QuestState or {DateKey="", Active={}, Stats={}}
	return data.QuestState
end

local function dayKey()
	local utc = os.date("!*t")
	return ("%04d-%03d"):format(utc.year, utc.yday)
end

local function choose(count)
	local pool = table.clone(Quests.Definitions)
	local active = {}
	for _=1, math.min(count,#pool) do
		local i = math.random(1,#pool)
		table.insert(active,{Id=pool[i].Id,Progress=0,Claimed=false})
		table.remove(pool,i)
	end
	return active
end

function QuestService.Init(allServices)
	services = allServices
end

function QuestService.EnsureDaily(player)
	local q = ensure(player)
	if not q then return end
	local key = dayKey()
	if q.DateKey ~= key then
		q.DateKey = key
		q.Active = choose(3)
		q.Stats = {}
	end
	return q
end

function QuestService.AddStat(player, stat, amount)
	local q = QuestService.EnsureDaily(player)
	if not q then return end
	q.Stats[stat] = (q.Stats[stat] or 0) + amount
	for _,state in ipairs(q.Active) do
		if not state.Claimed then
			for _,def in ipairs(Quests.Definitions) do
				if def.Id == state.Id and def.Stat == stat then
					state.Progress = math.min(def.Goal, q.Stats[stat])
					if state.Progress >= def.Goal then
						state.Claimed = true
						services.PlayerDataService.Add(player,"Tickets",def.Reward)
						ReplicatedStorage[Network.FolderName].Toast:FireClient(player,("QUEST COMPLETE +%d TICKETS"):format(def.Reward))
					end
					break
				end
			end
		end
	end
	ReplicatedStorage[Network.FolderName].QuestUpdate:FireClient(player,q)
end

function QuestService.Reroll(player)
	local q = QuestService.EnsureDaily(player)
	if not q then return false end
	q.Active = choose(3)
	q.Stats = {}
	ReplicatedStorage[Network.FolderName].QuestUpdate:FireClient(player,q)
	return true
end

return QuestService
