--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Network = require(ReplicatedStorage.Shared.Network)
local Config = require(ReplicatedStorage.Shared.Config)
local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)

local gui = Instance.new("ScreenGui")
gui.Name = "PlaygroundHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function roundRect(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,radius)
	corner.Parent = parent
end

local wakeFrame = Instance.new("Frame")
wakeFrame.Name = "WakeMeter"
wakeFrame.Size = UDim2.fromScale(0.38,0.04)
wakeFrame.Position = UDim2.fromScale(0.31,0.045)
wakeFrame.BackgroundColor3 = Color3.fromRGB(18,20,28)
wakeFrame.BorderSizePixel = 0
wakeFrame.Parent = gui
roundRect(wakeFrame,14)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0,1)
fill.BackgroundColor3 = Color3.fromRGB(255,78,92)
fill.BorderSizePixel = 0
fill.Parent = wakeFrame
roundRect(fill,14)

local wakeText = Instance.new("TextLabel")
wakeText.BackgroundTransparency = 1
wakeText.Size = UDim2.fromScale(1,1)
wakeText.Text = "PLAYGROUND AWAKE: 0%"
wakeText.TextColor3 = Color3.new(1,1,1)
wakeText.Font = Enum.Font.GothamBlack
wakeText.TextScaled = true
wakeText.Parent = wakeFrame

local roundText = Instance.new("TextLabel")
roundText.BackgroundTransparency = 1
roundText.Size = UDim2.fromScale(0.34,0.045)
roundText.Position = UDim2.fromScale(0.33,0.095)
roundText.TextColor3 = Color3.new(1,1,1)
roundText.Font = Enum.Font.GothamBold
roundText.TextScaled = true
roundText.Text = "LOADING..."
roundText.Parent = gui

local stageFrame = Instance.new("Frame")
stageFrame.Size = UDim2.fromScale(0.34,0.045)
stageFrame.Position = UDim2.fromScale(0.33,0.145)
stageFrame.BackgroundColor3 = Color3.fromRGB(18,20,28)
stageFrame.BackgroundTransparency = 0.08
stageFrame.BorderSizePixel = 0
stageFrame.Parent = gui
roundRect(stageFrame,12)

local stageFill = Instance.new("Frame")
stageFill.Size = UDim2.fromScale(0,1)
stageFill.BackgroundColor3 = Color3.fromRGB(79,238,150)
stageFill.BorderSizePixel = 0
stageFill.Parent = stageFrame
roundRect(stageFill,12)

local stageText = Instance.new("TextLabel")
stageText.BackgroundTransparency = 1
stageText.Size = UDim2.fromScale(1,1)
stageText.Text = ("STAGE 0 / %d"):format(Config.Map.SectionCount)
stageText.TextColor3 = Color3.new(1,1,1)
stageText.Font = Enum.Font.GothamBlack
stageText.TextScaled = true
stageText.Parent = stageFrame

local hint = Instance.new("TextLabel")
hint.BackgroundColor3 = Color3.fromRGB(15,17,24)
hint.BackgroundTransparency = 0.2
hint.Size = UDim2.fromScale(0.32,0.035)
hint.Position = UDim2.fromScale(0.34,0.94)
hint.Text = "SHIFT SPRINT  •  SPACE JUMP  •  Q/E LEAN"
hint.TextColor3 = Color3.fromRGB(205,214,235)
hint.Font = Enum.Font.GothamBold
hint.TextScaled = true
hint.Parent = gui
roundRect(hint,10)

local toast = Instance.new("TextLabel")
toast.BackgroundColor3 = Color3.fromRGB(15,15,22)
toast.BackgroundTransparency = 0.08
toast.Size = UDim2.fromScale(0.58,0.07)
toast.Position = UDim2.fromScale(0.21,0.80)
toast.TextColor3 = Color3.new(1,1,1)
toast.Font = Enum.Font.GothamBlack
toast.TextScaled = true
toast.Visible = false
toast.Parent = gui
roundRect(toast,14)

local toastGeneration = 0
local function showToast(message: string)
	toastGeneration += 1
	local generation = toastGeneration
	toast.Text = message
	toast.Visible = true
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.08

	task.delay(2.35,function()
		if generation ~= toastGeneration then return end
		TweenService:Create(toast,TweenInfo.new(0.3),{
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.wait(0.32)
		if generation == toastGeneration then
			toast.Visible = false
		end
	end)
end

local function setStage(index: number)
	index = math.clamp(index,0,Config.Map.SectionCount)
	stageText.Text = ("STAGE %d / %d"):format(index,Config.Map.SectionCount)
	TweenService:Create(
		stageFill,
		TweenInfo.new(0.35,Enum.EasingStyle.Quint),
		{Size = UDim2.fromScale(index/Config.Map.SectionCount,1)}
	):Play()
end

remotes.State.OnClientEvent:Connect(function(state)
	local wake = math.clamp(state.wake or 0,0,100)
	wakeText.Text = ("PLAYGROUND AWAKE: %d%%"):format(wake)
	TweenService:Create(
		fill,
		TweenInfo.new(0.35,Enum.EasingStyle.Quint),
		{Size = UDim2.fromScale(wake/100,1)}
	):Play()
end)

remotes.Round.OnClientEvent:Connect(function(state)
	local phase = state.phase or "RUN"
	local seconds = math.max(0,state.seconds or 0)
	roundText.Text = ("%s  •  %02d:%02d"):format(phase,math.floor(seconds/60),seconds%60)

	if phase == "INTERMISSION" and seconds == Config.Game.IntermissionSeconds then
		setStage(0)
	end
end)

remotes.Toast.OnClientEvent:Connect(showToast)

remotes.Checkpoint.OnClientEvent:Connect(function(index,reward)
	setStage(index)
	if index >= Config.Map.SectionCount then
		showToast(("FINAL CHECKPOINT!  +%d TICKETS  •  FIND THE EXIT!"):format(reward))
	else
		showToast(("STAGE %d CLEARED  •  +%d TICKETS"):format(index,reward))
	end
end)

remotes.Eliminated.OnClientEvent:Connect(function()
	showToast("YOU DIED — HAPPY WOKE UP MORE.")
end)
