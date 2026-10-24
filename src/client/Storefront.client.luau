--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)

local gui = Instance.new("ScreenGui")
gui.Name = "Storefront"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(116,52)
open.Position = UDim2.new(1,-134,1,-72)
open.BackgroundColor3 = Color3.fromRGB(255,208,56)
open.Text = "STORE"
open.Font = Enum.Font.GothamBlack
open.TextScaled = true
open.TextColor3 = Color3.fromRGB(24,24,30)
open.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0,14)
oc.Parent = open

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1,1)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = .28
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(.78,.82)
panel.Position = UDim2.fromScale(.5,.5)
panel.AnchorPoint = Vector2.new(.5,.5)
panel.BackgroundColor3 = Color3.fromRGB(19,21,29)
panel.Parent = overlay
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0,20)
pc.Parent = panel

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1,-90,0,58)
header.Position = UDim2.fromOffset(24,12)
header.Text = "HAPPY'S ADD-ONS"
header.Font = Enum.Font.GothamBlack
header.TextScaled = true
header.TextColor3 = Color3.new(1,1,1)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Size = UDim2.new(1,-110,0,28)
sub.Position = UDim2.fromOffset(24,65)
sub.Text = "PASSES = PERMANENT  •  PRODUCTS = ONE-TIME"
sub.Font = Enum.Font.GothamBold
sub.TextScaled = true
sub.TextColor3 = Color3.fromRGB(175,187,208)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(48,48)
close.Position = UDim2.new(1,-62,0,16)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBlack
close.TextScaled = true
close.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-36,1,-112)
scroll.Position = UDim2.fromOffset(18,102)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(.48,0,0,116)
grid.CellPadding = UDim2.fromOffset(12,12)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroll

local function toast(text:string)
	local ev = remotes:FindFirstChild(Network.Events.Toast)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer(text)
	end
end

local function makeCard(title:string, subtitle:string, accent:Color3, status:string, callback:()->())
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = Color3.fromRGB(38,42,55)
	b.Text = ""
	b.AutoButtonColor = true
	b.Parent = scroll

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,14)
	c.Parent = b

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0,6,1,-18)
	bar.Position = UDim2.fromOffset(9,9)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.Parent = b
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1,0)
	bc.Parent = bar

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1,-125,0,34)
	t.Position = UDim2.fromOffset(28,10)
	t.Text = title
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.new(1,1,1)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = b

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(88,28)
	badge.Position = UDim2.new(1,-98,0,10)
	badge.BackgroundColor3 = accent
	badge.TextColor3 = Color3.fromRGB(20,22,28)
	badge.Text = status
	badge.Font = Enum.Font.GothamBlack
	badge.TextScaled = true
	badge.Parent = b
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0,9)
	badgeCorner.Parent = badge

	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Size = UDim2.new(1,-40,0,48)
	s.Position = UDim2.fromOffset(28,52)
	s.Text = subtitle
	s.TextWrapped = true
	s.Font = Enum.Font.Gotham
	s.TextScaled = true
	s.TextColor3 = Color3.fromRGB(190,198,216)
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.Parent = b

	b.Activated:Connect(callback)
	return b
end

local function product(title:string, subtitle:string, key:string)
	local id = Config.Products[key]
	local ready = id and id ~= 0
	makeCard(title, subtitle, Color3.fromRGB(48,191,255), ready and "BUY" or "SETUP", function()
		if ready then
			MarketplaceService:PromptProductPurchase(player,id)
		else
			warn("Missing Developer Product ID",key)
		end
	end)
end

local function pass(title:string, subtitle:string, key:string)
	local id = Config.GamePasses[key]
	local ready = id and id ~= 0
	makeCard(title, subtitle, Color3.fromRGB(255,196,60), ready and "PASS" or "SETUP", function()
		if ready then
			MarketplaceService:PromptGamePassPurchase(player,id)
		else
			warn("Missing Game Pass ID",key)
		end
	end)
end

pass("VIP","Permanent +25% ticket earnings and VIP status.","VIP")
pass("2X TICKETS","Permanent double ticket earnings.","DoubleTickets")
pass("SPEED COIL","Permanent small sprint boost.","SpeedCoil")
pass("GRAVITY COIL","Permanent small jump-assist boost.","GravityCoil")
pass("PREMIUM TRAIL","Exclusive animated Happy Gold trail.","PremiumTrail")
pass("CHECKPOINT AURA","Premium checkpoint arrival effect.","CheckpointAura")
pass("EXTRA COMPANION","Unlock another companion slot.","ExtraCompanionSlot")
pass("EXCLUSIVE EMOTES","Premium emote set.","ExclusiveEmotes")
pass("GOLDEN NAME","Gold chat/name treatment.","GoldenName")

product("REVIVE","Bank one revive for a failed run.","Revive")
product("TEAM REVIVE","Give everyone in the server a revive.","ReviveTeam")
product("SKIP STAGE","Skip exactly your current stage.","SkipStage")
product("500 TICKETS","Small ticket currency pack.","Tickets500")
product("1,500 TICKETS","Medium ticket currency pack.","Tickets1500")
product("5,000 TICKETS","Large ticket currency pack.","Tickets5000")
product("LOW GRAVITY","Trigger low gravity for the whole server.","LowGravityServer")
product("TINY MODE","Shrink the whole server temporarily.","TinyServer")
product("BLACKOUT","Turn the lights out for the whole server.","BlackoutServer")
product("CALM SERVER","Reduce Happy's Wake for everyone.","SaveTheServer")
product("UNLEASH CHAOS","Trigger a random Wake event.","ChaosEvent")
product("WAKE HAPPY","Push Happy's Wake meter forward.","WakeSkip")
product("REROLL QUESTS","Generate three new daily quests.","QuestReroll")

open.Activated:Connect(function()
	overlay.Visible = true
end)
close.Activated:Connect(function()
	overlay.Visible = false
end)
