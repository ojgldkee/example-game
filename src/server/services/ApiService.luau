--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Network=require(ReplicatedStorage.Shared.Network)

local ApiService={}
local services
local rate:{[Player]:{window:number,count:number}}={}

local function allowed(player)
	local now=os.clock()
	local r=rate[player]
	if not r or now-r.window>=1 then rate[player]={window=now,count=1}; return true end
	r.count+=1
	return r.count<=12
end

local function fn(name)
	return ReplicatedStorage[Network.FolderName][name] :: RemoteFunction
end

function ApiService.Init(allServices)
	services=allServices
	fn(Network.Functions.GetSnapshot).OnServerInvoke=function(player)
		if not allowed(player) then return nil end
		services.QuestService.EnsureDaily(player)
		return services.PlayerDataService.GetSnapshot(player)
	end
	fn(Network.Functions.ClaimDaily).OnServerInvoke=function(player)
		if not allowed(player) then return false,"Rate limited" end
		return services.DailyRewardService.Claim(player)
	end
	fn(Network.Functions.PurchaseCosmetic).OnServerInvoke=function(player,id)
		if not allowed(player) or typeof(id)~="string" then return false,"Invalid" end
		local ok,res=services.CosmeticService.Purchase(player,id)
		services.PlayerDataService.MarkDirty(player)
		return ok,res
	end
	fn(Network.Functions.EquipCosmetic).OnServerInvoke=function(player,id)
		if not allowed(player) or typeof(id)~="string" then return false,"Invalid" end
		local ok,res=services.CosmeticService.Equip(player,id)
		services.PlayerDataService.MarkDirty(player)
		return ok,res
	end
	fn(Network.Functions.UpdateSettings).OnServerInvoke=function(player,key,value)
		if not allowed(player) then return false end
		local ok,res=services.SettingsService.Update(player,key,value)
		if ok then services.PlayerDataService.MarkDirty(player) end
		return ok,res
	end
	fn(Network.Functions.RerollQuest).OnServerInvoke=function(player)
		if not allowed(player) then return false end
		return services.QuestService.Reroll(player)
	end
	fn(Network.Functions.PurchaseUpgrade).OnServerInvoke=function(player,id)
		if not allowed(player) or typeof(id)~="string" then return false,"Invalid" end
		return services.UpgradeService.Purchase(player,id)
	end
end

return ApiService
