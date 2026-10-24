--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local PurchaseService = {}
local services

local function identifyProduct(productId: number): string?
	for name, id in pairs(Config.Products) do
		if id ~= 0 and id == productId then return name end
	end
	return nil
end

local function grant(player: Player, productName: string)
	if productName == "Revive" then
		services.PlayerDataService.Add(player, "Revives", 1)
	elseif productName == "Tickets500" then
		services.PlayerDataService.Add(player, "Tickets", Config.ProductRewards.Tickets500)
	elseif productName == "Tickets1500" then
		services.PlayerDataService.Add(player, "Tickets", Config.ProductRewards.Tickets1500)
	elseif productName == "SaveTheServer" then
		services.WakeService.Add(-Config.ProductRewards.SaveTheServerWakeReduction)
	elseif productName == "ChaosEvent" then
		ReplicatedStorage[Network.FolderName].Toast:FireAllClients(player.DisplayName .. " unleashed CHAOS!")
		services.WakeService.Add(10)
	end
end

function PurchaseService.Init(allServices)
	services = allServices
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = services.PlayerDataService.Get(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local receiptKey = tostring(receiptInfo.PurchaseId)
		data.Receipts = data.Receipts or {}
		if data.Receipts[receiptKey] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local productName = identifyProduct(receiptInfo.ProductId)
		if not productName then
			warn("Unknown developer product:", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		grant(player, productName)
		data.Receipts[receiptKey] = true
		services.PlayerDataService.Save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return PurchaseService
