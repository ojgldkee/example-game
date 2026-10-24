--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Network = require(ReplicatedStorage.Shared.Network)

local UpgradeService = {}
local services

local function ensureLevels(data)
	data.Upgrades = data.Upgrades or Upgrades.DefaultLevels()
	for _, id in ipairs(Upgrades.Order) do
		if data.Upgrades[id] == nil then
			data.Upgrades[id] = 0
		end
	end
	return data.Upgrades
end

local function applyAttributes(player: Player)
	local data = services.PlayerDataService.Get(player)
	if not data then return end

	local levels = ensureLevels(data)
	local sprint = levels.Sprint or 0
	local jump = levels.JumpAssist or 0
	local armor = levels.Armor or 0
	local health = levels.Health or 0

	player:SetAttribute("ObbySprintSpeed", Config.Movement.SprintSpeed + sprint * Upgrades.Definitions.Sprint.SprintSpeedPerLevel)
	player:SetAttribute("ObbyJumpPower", Config.Movement.JumpPower + jump * Upgrades.Definitions.JumpAssist.JumpPowerPerLevel)
	player:SetAttribute("ObbyHazardMultiplier", math.max(0.45, 1 - armor * Upgrades.Definitions.Armor.DamageReductionPerLevel))
	player:SetAttribute("ObbyTicketMultiplier", 1 + (levels.TicketBoost or 0) * Upgrades.Definitions.TicketBoost.TicketMultiplierPerLevel)
	player:SetAttribute("ObbyMaxHealthBonus", health * Upgrades.Definitions.Health.MaxHealthPerLevel)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local maxHealth = 100 + (player:GetAttribute("ObbyMaxHealthBonus") or 0)
		humanoid.MaxHealth = maxHealth
		humanoid.Health = math.min(maxHealth, math.max(humanoid.Health, maxHealth))
	end
end

local function waitForData(player: Player)
	for _=1,100 do
		if services.PlayerDataService.Get(player) then
			applyAttributes(player)
			return
		end
		task.wait(0.1)
	end
end

local function bindPlayer(player: Player)
	task.spawn(waitForData, player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				applyAttributes(player)
			end
		end)
	end)
end

function UpgradeService.Init(allServices)
	services = allServices
	Players.PlayerAdded:Connect(bindPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
end

function UpgradeService.Purchase(player: Player, id: string)
	local def = Upgrades.Definitions[id]
	if not def then return false, "Unknown upgrade" end

	local data = services.PlayerDataService.Get(player)
	if not data then return false, "Profile loading" end

	local levels = ensureLevels(data)
	local current = levels[id] or 0
	if current >= def.MaxLevel then
		return false, "MAX LEVEL"
	end

	local cost = def.Costs[current + 1]
	if not cost then return false, "No cost configured" end
	if (data.Tickets or 0) < cost then
		return false, ("Need %d tickets"):format(cost)
	end

	data.Tickets -= cost
	levels[id] = current + 1
	services.PlayerDataService.MarkDirty(player)
	services.PlayerDataService.Set(player, "Upgrades", levels)
	applyAttributes(player)

	local folder = ReplicatedStorage:FindFirstChild(Network.FolderName)
	local toast = folder and folder:FindFirstChild(Network.Events.Toast)
	if toast and toast:IsA("RemoteEvent") then
		toast:FireClient(player, ("%s LEVEL %d"):format(def.Name, levels[id]))
	end

	return true, {
		id = id,
		level = levels[id],
		tickets = data.Tickets,
		upgrades = levels,
	}
end

function UpgradeService.HazardMultiplier(player: Player): number
	local value = player:GetAttribute("ObbyHazardMultiplier")
	return typeof(value) == "number" and value or 1
end

function UpgradeService.TicketMultiplier(player: Player): number
	local value = player:GetAttribute("ObbyTicketMultiplier")
	return typeof(value) == "number" and value or 1
end

function UpgradeService.GetLevels(player: Player)
	local data = services.PlayerDataService.Get(player)
	if not data then return Upgrades.DefaultLevels() end
	return ensureLevels(data)
end

return UpgradeService
