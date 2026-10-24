--!strict
local MarketplaceService=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)

local EntitlementService={}
local owned:{[Player]:{[string]:boolean}}={}

local function refresh(player)
	local state={}
	for name,id in pairs(Config.GamePasses) do
		if id==0 then state[name]=false else
			local ok,res=pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId,id) end)
			state[name]=ok and res or false
		end
	end
	owned[player]=state
	player:SetAttribute("PassSpeedCoil", state.SpeedCoil == true)
	player:SetAttribute("PassGravityCoil", state.GravityCoil == true)
	return state
end

function EntitlementService.Init(_services)
	Players.PlayerAdded:Connect(function(p) task.spawn(refresh,p) end)
	Players.PlayerRemoving:Connect(function(p) owned[p]=nil end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
		if not purchased then return end
		for name,id in pairs(Config.GamePasses) do
			if id==passId then
				owned[player]=owned[player] or {}
				owned[player][name]=true
				if name=="SpeedCoil" then player:SetAttribute("PassSpeedCoil", true) end
				if name=="GravityCoil" then player:SetAttribute("PassGravityCoil", true) end
				break
			end
		end
	end)
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(refresh,p) end
end

function EntitlementService.Has(player,name)
	local state=owned[player]
	if not state then state=refresh(player) end
	return state[name]==true
end

function EntitlementService.TicketMultiplier(player)
	local mult=1
	if EntitlementService.Has(player,"VIP") then mult*=Config.Economy.VIPTicketMultiplier end
	if EntitlementService.Has(player,"DoubleTickets") then mult*=Config.Economy.DoubleTicketsMultiplier end
	return mult
end

return EntitlementService
