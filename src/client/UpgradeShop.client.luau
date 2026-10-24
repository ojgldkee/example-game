--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Network = require(ReplicatedStorage.Shared.Network)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)

local getSnapshot = remotes:WaitForChild(Network.Functions.GetSnapshot) :: RemoteFunction
local purchaseUpgrade = remotes:WaitForChild(Network.Functions.PurchaseUpgrade) :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "UpgradeShop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Name = "OpenUpgrades"
open.Size = UDim2.fromOffset(150,50)
open.Position = UDim2.new(0,18,1,-72)
open.BackgroundColor3 = Color3.fromRGB(67,225,155)
open.TextColor3 = Color3.fromRGB(15,22,25)
open.Text = "UPGRADES"
open.Font = Enum.Font.GothamBlack
open.TextScaled = true
open.Parent = gui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0,14)
openCorner.Parent = open

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1,1)
shade.BackgroundColor3 = Color3.new(0,0,0)
shade.BackgroundTransparency = .35
shade.Visible = false
shade.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(.68,.76)
panel.Position = UDim2.fromScale(.5,.5)
panel.AnchorPoint = Vector2.new(.5,.5)
panel.BackgroundColor3 = Color3.fromRGB(18,20,28)
panel.Parent = shade
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0,20)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-90,0,58)
title.Position = UDim2.fromOffset(22,12)
title.Text = "PERMANENT UPGRADES"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local balance = Instance.new("TextLabel")
balance.BackgroundTransparency = 1
balance.Size = UDim2.new(.45,0,0,34)
balance.Position = UDim2.new(0,22,0,64)
balance.Text = "TICKETS: 150"
balance.TextColor3 = Color3.fromRGB(255,216,66)
balance.Font = Enum.Font.GothamBold
balance.TextScaled = true
balance.TextXAlignment = Enum.TextXAlignment.Left
balance.Parent = panel

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Size = UDim2.new(.5,-30,0,34)
sub.Position = UDim2.new(.5,0,0,64)
sub.Text = "FREE ROUTE IS ALWAYS BEATABLE"
sub.TextColor3 = Color3.fromRGB(166,181,205)
sub.Font = Enum.Font.GothamBold
sub.TextScaled = true
sub.TextXAlignment = Enum.TextXAlignment.Right
sub.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(48,48)
close.Position = UDim2.new(1,-62,0,14)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBlack
close.TextScaled = true
close.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-32,1,-116)
scroll.Position = UDim2.fromOffset(16,108)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0,10)
list.Parent = scroll

local levels: {[string]: number} = {}
local tickets = 0
local cards: {[string]: {button: TextButton, level: TextLabel, cost: TextLabel}} = {}

local function nextCost(id: string): number?
	local def = Upgrades.Definitions[id]
	local level = levels[id] or 0
	if level >= def.MaxLevel then return nil end
	return def.Costs[level+1]
end

local function refreshCard(id: string)
	local def = Upgrades.Definitions[id]
	local card = cards[id]
	if not card then return end
	local level = levels[id] or 0
	card.level.Text = ("LEVEL %d / %d"):format(level,def.MaxLevel)
	local cost = nextCost(id)
	if cost then
		card.cost.Text = ("%d TICKETS"):format(cost)
		card.button.Text = tickets >= cost and "UPGRADE" or "NEED TICKETS"
		card.button.AutoButtonColor = tickets >= cost
	else
		card.cost.Text = "MAXED"
		card.button.Text = "MAX LEVEL"
		card.button.AutoButtonColor = false
	end
end

local function refreshAll()
	balance.Text = ("TICKETS: %d"):format(tickets)
	for _, id in ipairs(Upgrades.Order) do
		refreshCard(id)
	end
end

for _, id in ipairs(Upgrades.Order) do
	local def = Upgrades.Definitions[id]
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,-8,0,102)
	card.BackgroundColor3 = Color3.fromRGB(34,38,50)
	card.BorderSizePixel = 0
	card.Parent = scroll
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0,14)
	cc.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(.46,-16,0,30)
	name.Position = UDim2.fromOffset(16,10)
	name.Text = def.Name
	name.TextColor3 = Color3.new(1,1,1)
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Size = UDim2.new(.53,-16,0,45)
	desc.Position = UDim2.fromOffset(16,43)
	desc.Text = def.Description
	desc.TextWrapped = true
	desc.TextColor3 = Color3.fromRGB(185,194,214)
	desc.Font = Enum.Font.Gotham
	desc.TextScaled = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = card

	local level = Instance.new("TextLabel")
	level.Text = "LEVEL 0 / 5"
	level.BackgroundTransparency = 1
	level.Size = UDim2.new(.19,0,0,28)
	level.Position = UDim2.new(.50,0,0,12)
	level.TextColor3 = Color3.fromRGB(85,225,165)
	level.Font = Enum.Font.GothamBold
	level.TextScaled = true
	level.Parent = card

	local cost = Instance.new("TextLabel")
	cost.Text = "LOADING..."
	cost.BackgroundTransparency = 1
	cost.Size = UDim2.new(.19,0,0,28)
	cost.Position = UDim2.new(.50,0,0,52)
	cost.TextColor3 = Color3.fromRGB(255,215,72)
	cost.Font = Enum.Font.GothamBold
	cost.TextScaled = true
	cost.Parent = card

	local buy = Instance.new("TextButton")
	buy.Text = "UPGRADE"
	buy.Size = UDim2.new(.25,-12,0,54)
	buy.Position = UDim2.new(.75,0,.5,-27)
	buy.BackgroundColor3 = Color3.fromRGB(67,225,155)
	buy.TextColor3 = Color3.fromRGB(15,22,25)
	buy.Font = Enum.Font.GothamBlack
	buy.TextScaled = true
	buy.Parent = card
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0,12)
	bc.Parent = buy

	cards[id] = {button=buy,level=level,cost=cost}

	buy.Activated:Connect(function()
		local costNow = nextCost(id)
		if not costNow or tickets < costNow then return end
		buy.Text = "..."
		local ok, result = pcall(function()
			return {purchaseUpgrade:InvokeServer(id)}
		end)
		if not ok then
			buy.Text = "RETRY"
			return
		end
		local values = result
		local success = values[1]
		local payload = values[2]
		if success and type(payload)=="table" then
			tickets = payload.tickets or tickets
			levels = payload.upgrades or levels
		end
		refreshAll()
	end)
end

local function loadProfile()
	for _=1,40 do
		local ok, snapshot = pcall(function()
			return getSnapshot:InvokeServer()
		end)
		if ok and snapshot then
			tickets = snapshot.Tickets or 0
			levels = snapshot.Upgrades or {}
			refreshAll()
			return
		end
		task.wait(.5)
	end
end

open.Activated:Connect(function()
	shade.Visible = true
	task.spawn(loadProfile)
end)
close.Activated:Connect(function()
	shade.Visible = false
end)

remotes.Profile.OnClientEvent:Connect(function(profile)
	if not profile then return end
	tickets = profile.Tickets or tickets
	levels = profile.Upgrades or levels
	if shade.Visible then refreshAll() end
end)

task.spawn(loadProfile)
