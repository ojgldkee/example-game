--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)

local gui = Instance.new("ScreenGui")
gui.Name = "PlaygroundShop"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Size = UDim2.fromScale(0.12, 0.055)
open.Position = UDim2.fromScale(0.86, 0.9)
open.AnchorPoint = Vector2.new(0.5,0.5)
open.Text = "SHOP"
open.Font = Enum.Font.GothamBlack
open.TextScaled = true
open.BackgroundColor3 = Color3.fromRGB(255, 212, 70)
open.TextColor3 = Color3.fromRGB(20,20,25)
open.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = open

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.38, 0.58)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(20,22,30)
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,18); pc.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(0.8,0.1)
title.Position = UDim2.fromScale(0.1,0.03)
title.Text = "PLAYGROUND SHOP"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromScale(0.1,0.08)
close.Position = UDim2.fromScale(0.87,0.03)
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextScaled = true
close.BackgroundTransparency = 1
close.TextColor3 = Color3.new(1,1,1)
close.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0,10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Top

local container = Instance.new("Frame")
container.BackgroundTransparency = 1
container.Size = UDim2.fromScale(0.9,0.78)
container.Position = UDim2.fromScale(0.05,0.16)
container.Parent = panel
list.Parent = container

local function addProduct(label: string, productId: number)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,48)
	b.Text = label
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(45, 190, 255)
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = container
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,12); bc.Parent = b
	b.Activated:Connect(function()
		if productId == 0 then
			warn("Product ID not configured for", label)
			return
		end
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
end

addProduct("REVIVE TOKEN", Config.Products.Revive)
addProduct("+500 TICKETS", Config.Products.Tickets500)
addProduct("+1,500 TICKETS", Config.Products.Tickets1500)
addProduct("CALM THE PLAYGROUND", Config.Products.SaveTheServer)
addProduct("UNLEASH CHAOS", Config.Products.ChaosEvent)

open.Activated:Connect(function() panel.Visible = true end)
close.Activated:Connect(function() panel.Visible = false end)
