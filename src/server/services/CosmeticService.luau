--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Cosmetics=require(ReplicatedStorage.Shared.Cosmetics)
local Network=require(ReplicatedStorage.Shared.Network)

local CosmeticService={}
local services

local function allItems()
	local arr={}
	for category,items in pairs(Cosmetics) do
		for _,item in ipairs(items) do
			arr[item.Id]={Category=category,Def=item}
		end
	end
	return arr
end
local itemIndex=allItems()

local function ensure(data)
	data.Cosmetics=data.Cosmetics or {Owned={none=true,rookie=true,poof=true},Equipped={Trails="none",Titles="rookie",DeathEffects="poof"}}
	return data.Cosmetics
end

function CosmeticService.Init(allServices) services=allServices end

function CosmeticService.Purchase(player,id)
	local data=services.PlayerDataService.Get(player)
	local entry=itemIndex[id]
	if not data or not entry then return false,"Invalid item" end
	local c=ensure(data)
	if c.Owned[id] then return false,"Owned" end
	if entry.Def.GamePass then return false,"Game pass item" end
	if (data.Tickets or 0) < entry.Def.Price then return false,"Not enough tickets" end
	data.Tickets -= entry.Def.Price
	c.Owned[id]=true
	ReplicatedStorage[Network.FolderName].CosmeticUpdate:FireClient(player,c)
	return true,c
end

function CosmeticService.Equip(player,id)
	local data=services.PlayerDataService.Get(player)
	local entry=itemIndex[id]
	if not data or not entry then return false,"Invalid item" end
	local c=ensure(data)
	if not c.Owned[id] then return false,"Not owned" end
	c.Equipped[entry.Category]=id
	ReplicatedStorage[Network.FolderName].CosmeticUpdate:FireClient(player,c)
	return true,c
end

return CosmeticService
