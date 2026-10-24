--!strict
local MarketplaceService=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui"); gui.Name="Storefront"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")

local open=Instance.new("TextButton"); open.Size=UDim2.fromOffset(116,52); open.Position=UDim2.new(1,-134,1,-72); open.BackgroundColor3=Color3.fromRGB(255,208,56); open.Text="STORE"; open.Font=Enum.Font.GothamBlack; open.TextScaled=true; open.TextColor3=Color3.fromRGB(24,24,30); open.Parent=gui
local oc=Instance.new("UICorner"); oc.CornerRadius=UDim.new(0,14); oc.Parent=open

local overlay=Instance.new("Frame"); overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0); overlay.BackgroundTransparency=.35; overlay.Visible=false; overlay.Parent=gui
local panel=Instance.new("Frame"); panel.Size=UDim2.fromScale(.72,.76); panel.Position=UDim2.fromScale(.5,.5); panel.AnchorPoint=Vector2.new(.5,.5); panel.BackgroundColor3=Color3.fromRGB(19,21,29); panel.Parent=overlay
local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,20); pc.Parent=panel

local header=Instance.new("TextLabel"); header.BackgroundTransparency=1; header.Size=UDim2.new(1,-90,0,64); header.Position=UDim2.fromOffset(24,14); header.Text="HAPPY'S STORE"; header.Font=Enum.Font.GothamBlack; header.TextScaled=true; header.TextColor3=Color3.new(1,1,1); header.TextXAlignment=Enum.TextXAlignment.Left; header.Parent=panel
local close=Instance.new("TextButton"); close.Size=UDim2.fromOffset(48,48); close.Position=UDim2.new(1,-62,0,16); close.BackgroundTransparency=1; close.Text="×"; close.TextColor3=Color3.new(1,1,1); close.Font=Enum.Font.GothamBlack; close.TextScaled=true; close.Parent=panel

local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-36,1,-98); scroll.Position=UDim2.fromOffset(18,82); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=6; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=panel
local grid=Instance.new("UIGridLayout"); grid.CellSize=UDim2.new(.48,0,0,104); grid.CellPadding=UDim2.fromOffset(12,12); grid.HorizontalAlignment=Enum.HorizontalAlignment.Center; grid.Parent=scroll

local function card(title,subtitle,accent,callback)
	local b=Instance.new("TextButton"); b.BackgroundColor3=Color3.fromRGB(38,42,55); b.Text=""; b.AutoButtonColor=true; b.Parent=scroll
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,14); c.Parent=b
	local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,6,1,-18); bar.Position=UDim2.fromOffset(9,9); bar.BackgroundColor3=accent; bar.BorderSizePixel=0; bar.Parent=b
	local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(1,0); bc.Parent=bar
	local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,-34,.48,0); t.Position=UDim2.fromOffset(28,10); t.Text=title; t.Font=Enum.Font.GothamBlack; t.TextScaled=true; t.TextColor3=Color3.new(1,1,1); t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=b
	local s=Instance.new("TextLabel"); s.BackgroundTransparency=1; s.Size=UDim2.new(1,-34,.35,0); s.Position=UDim2.new(0,28,.55,0); s.Text=subtitle; s.Font=Enum.Font.Gotham; s.TextScaled=true; s.TextColor3=Color3.fromRGB(190,198,216); s.TextXAlignment=Enum.TextXAlignment.Left; s.Parent=b
	b.Activated:Connect(callback)
end

local function product(title,subtitle,key)
	card(title,subtitle,Color3.fromRGB(48,191,255),function()
		local id=Config.Products[key]
		if id and id~=0 then MarketplaceService:PromptProductPurchase(player,id) else warn("Missing product ID",key) end
	end)
end
local function pass(title,subtitle,key)
	card(title,subtitle,Color3.fromRGB(255,196,60),function()
		local id=Config.GamePasses[key]
		if id and id~=0 then MarketplaceService:PromptGamePassPurchase(player,id) else warn("Missing pass ID",key) end
	end)
end

pass("VIP","Bonus tickets + VIP status","VIP")
pass("2× TICKETS","Permanent ticket multiplier","DoubleTickets")
pass("PREMIUM TRAIL","Exclusive Happy Gold trail","PremiumTrail")
pass("EXTRA COMPANION","Extra companion slot","ExtraCompanionSlot")
pass("EXCLUSIVE EMOTES","Premium emote set","ExclusiveEmotes")
pass("GOLDEN NAME","Gold chat/name treatment","GoldenName")
product("REVIVE","Keep a revive token ready","Revive")
product("TEAM REVIVE","Give the whole server a revive","ReviveTeam")
product("SKIP STAGE","Skip exactly your current stage","SkipStage")
product("500 TICKETS","Cosmetic currency pack","Tickets500")
product("1,500 TICKETS","Better value currency pack","Tickets1500")
product("5,000 TICKETS","Large cosmetic currency pack","Tickets5000")
product("CALM SERVER","Reduce Wake for everyone","SaveTheServer")
product("UNLEASH CHAOS","Trigger a Wake event","ChaosEvent")
product("WAKE IT UP","Push the Wake meter forward","WakeSkip")
product("REROLL QUESTS","Get three different quests","QuestReroll")

open.Activated:Connect(function() overlay.Visible=true end)
close.Activated:Connect(function() overlay.Visible=false end)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 and input.Position.X<panel.AbsolutePosition.X then overlay.Visible=false end
end)
