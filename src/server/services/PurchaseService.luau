--!strict
local MarketplaceService=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local Network=require(ReplicatedStorage.Shared.Network)

local PurchaseService={}
local services

local function identify(id)
	for name,pid in pairs(Config.Products) do if pid~=0 and pid==id then return name end end
	return nil
end

local function toastAll(text) ReplicatedStorage[Network.FolderName].Toast:FireAllClients(text) end
local function grant(player,name)
	if name=="Revive" then
		services.PlayerDataService.Add(player,"Revives",1)
	elseif name=="ReviveTeam" then
		for _,p in ipairs(Players:GetPlayers()) do services.PlayerDataService.Add(p,"Revives",1) end
		toastAll(player.DisplayName.." gave everyone a revive!")
	elseif name=="Tickets500" then services.PlayerDataService.Add(player,"Tickets",500)
	elseif name=="Tickets1500" then services.PlayerDataService.Add(player,"Tickets",1500)
	elseif name=="Tickets5000" then services.PlayerDataService.Add(player,"Tickets",5000)
	elseif name=="SaveTheServer" then
		services.WakeService.Add(-Config.ProductRewards.SaveTheServerWakeReduction)
		toastAll(player.DisplayName.." calmed the playground.")
	elseif name=="ChaosEvent" then
		services.WakeService.Add(Config.ProductRewards.ChaosWakeIncrease)
		services.WakeEventService.TryRandom()
		toastAll(player.DisplayName.." unleashed CHAOS!")
	elseif name=="WakeSkip" then
		services.WakeService.Add(Config.ProductRewards.WakeSkipIncrease)
		toastAll(player.DisplayName.." woke Happy up faster!")
	elseif name=="QuestReroll" then
		services.QuestService.Reroll(player)
	end
end

function PurchaseService.Init(allServices)
	services=allServices
	MarketplaceService.ProcessReceipt=function(info)
		local player=Players:GetPlayerByUserId(info.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local data=services.PlayerDataService.Get(player)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local key=tostring(info.PurchaseId)
		data.Receipts=data.Receipts or {}
		if data.Receipts[key] then return Enum.ProductPurchaseDecision.PurchaseGranted end
		local name=identify(info.ProductId)
		if not name then warn("Unknown product",info.ProductId); return Enum.ProductPurchaseDecision.NotProcessedYet end
		local ok,err=pcall(grant,player,name)
		if not ok then warn("Grant failed",name,err); return Enum.ProductPurchaseDecision.NotProcessedYet end
		data.Receipts[key]=true
		services.PlayerDataService.MarkDirty(player)
		services.PlayerDataService.Save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end
return PurchaseService
