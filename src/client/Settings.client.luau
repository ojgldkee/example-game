--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Network=require(ReplicatedStorage.Shared.Network)

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild(Network.FolderName)
local update=remotes:WaitForChild(Network.Functions.UpdateSettings) :: RemoteFunction

local gui=Instance.new("ScreenGui"); gui.Name="SettingsUI"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local button=Instance.new("TextButton"); button.Size=UDim2.fromOffset(48,48); button.Position=UDim2.new(1,-64,0,18); button.Text="⚙"; button.TextScaled=true; button.BackgroundColor3=Color3.fromRGB(25,27,36); button.TextColor3=Color3.new(1,1,1); button.Parent=gui
local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,12); bc.Parent=button
local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(330,380); panel.Position=UDim2.new(1,-350,0,78); panel.BackgroundColor3=Color3.fromRGB(18,20,28); panel.Visible=false; panel.Parent=gui
local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,16); pc.Parent=panel
local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,10); list.HorizontalAlignment=Enum.HorizontalAlignment.Center; list.Parent=panel
local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,18); pad.Parent=panel

local current={Music=true,SFX=true,CameraShake=true,ReducedFlashes=false,PerformanceMode=false,AutoSpectate=true}
local labels={Music="Music",SFX="Sound Effects",CameraShake="Camera Shake",ReducedFlashes="Reduced Flashes",PerformanceMode="Performance Mode",AutoSpectate="Auto Spectate"}

local function addToggle(key)
	local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-28,0,48); b.BackgroundColor3=Color3.fromRGB(40,45,60); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextScaled=true; b.Parent=panel
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
	local function refresh() b.Text=labels[key]..": "..(current[key] and "ON" or "OFF") end
	b.Activated:Connect(function()
		local ok,res=update:InvokeServer(key,not current[key])
		if ok then current=res; refresh() end
	end)
	refresh()
end
for _,key in ipairs({"Music","SFX","CameraShake","ReducedFlashes","PerformanceMode","AutoSpectate"}) do addToggle(key) end

button.Activated:Connect(function() panel.Visible=not panel.Visible end)
remotes.Profile.OnClientEvent:Connect(function(profile)
	if profile and profile.Settings then
		current=profile.Settings
		for _,child in ipairs(panel:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _,key in ipairs({"Music","SFX","CameraShake","ReducedFlashes","PerformanceMode","AutoSpectate"}) do addToggle(key) end
	end
end)
