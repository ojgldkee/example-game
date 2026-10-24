--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Network=require(ReplicatedStorage.Shared.Network)

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild(Network.FolderName)
local settings={CameraShake=true,ReducedFlashes=false,PerformanceMode=false}

local gui=Instance.new("ScreenGui"); gui.Name="WakeEventFX"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=50; gui.Parent=player:WaitForChild("PlayerGui")
local flash=Instance.new("Frame"); flash.Size=UDim2.fromScale(1,1); flash.BackgroundColor3=Color3.fromRGB(255,35,35); flash.BackgroundTransparency=1; flash.BorderSizePixel=0; flash.Parent=gui
local banner=Instance.new("TextLabel"); banner.Size=UDim2.fromScale(.7,.11); banner.Position=UDim2.fromScale(.15,.18); banner.BackgroundColor3=Color3.fromRGB(10,10,14); banner.BackgroundTransparency=.12; banner.TextColor3=Color3.new(1,1,1); banner.Font=Enum.Font.GothamBlack; banner.TextScaled=true; banner.Visible=false; banner.Parent=gui
local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,16); bc.Parent=banner

local function pulse(color)
	if settings.ReducedFlashes then return end
	flash.BackgroundColor3=color
	flash.BackgroundTransparency=.65
	TweenService:Create(flash,TweenInfo.new(.45),{BackgroundTransparency=1}):Play()
end

local function show(text,duration)
	banner.Text=text; banner.TextTransparency=0; banner.Visible=true
	task.delay(math.min(duration or 3,3.5),function()
		TweenService:Create(banner,TweenInfo.new(.3),{TextTransparency=1}):Play()
		task.wait(.32); banner.Visible=false
	end)
end

local function shake(seconds,intensity)
	if not settings.CameraShake or settings.PerformanceMode then return end
	local camera=workspace.CurrentCamera
	if not camera then return end
	local started=os.clock()
	local connection
	connection=RunService.RenderStepped:Connect(function()
		if os.clock()-started>=seconds then connection:Disconnect(); return end
		local x=(math.random()-.5)*intensity
		local y=(math.random()-.5)*intensity
		camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(y),math.rad(x),0)
	end)
end

remotes.Profile.OnClientEvent:Connect(function(profile)
	if profile and profile.Settings then settings=profile.Settings end
end)

remotes.ServerEvent.OnClientEvent:Connect(function(event)
	show(event.text or "SOMETHING CHANGED",event.duration)
	if event.id=="red_alert" or event.id=="blackout_chase" then pulse(Color3.fromRGB(255,30,30)) end
	if event.id=="camera_shake" or event.id=="platform_pulse" or event.id=="monster_sprint" then shake(math.min(event.duration or 2,3),1.6) end
end)

remotes.MonsterEvent.OnClientEvent:Connect(function(event)
	if event.type=="jumpscare" then
		pulse(Color3.new(1,1,1)); shake(.45,4.2); show("HAPPY FOUND YOU",1.2)
	end
end)
