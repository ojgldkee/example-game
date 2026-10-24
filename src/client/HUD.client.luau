--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Network = require(ReplicatedStorage.Shared.Network)
local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)

local gui = Instance.new("ScreenGui")
gui.Name = "PlaygroundHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local wakeFrame = Instance.new("Frame")
wakeFrame.Name = "WakeMeter"
wakeFrame.Size = UDim2.fromScale(0.36, 0.035)
wakeFrame.Position = UDim2.fromScale(0.32, 0.045)
wakeFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
wakeFrame.BorderSizePixel = 0
wakeFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = wakeFrame

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 83, 83)
fill.BorderSizePixel = 0
fill.Parent = wakeFrame
local fillCorner = corner:Clone()
fillCorner.Parent = fill

local wakeText = Instance.new("TextLabel")
wakeText.BackgroundTransparency = 1
wakeText.Size = UDim2.fromScale(1, 1)
wakeText.Text = "PLAYGROUND AWAKE: 0%"
wakeText.TextColor3 = Color3.new(1,1,1)
wakeText.Font = Enum.Font.GothamBold
wakeText.TextScaled = true
wakeText.Parent = wakeFrame

local roundText = Instance.new("TextLabel")
roundText.BackgroundTransparency = 1
roundText.Size = UDim2.fromScale(0.32, 0.05)
roundText.Position = UDim2.fromScale(0.34, 0.095)
roundText.TextColor3 = Color3.new(1,1,1)
roundText.Font = Enum.Font.GothamBold
roundText.TextScaled = true
roundText.Text = "LOADING..."
roundText.Parent = gui

local toast = Instance.new("TextLabel")
toast.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
toast.BackgroundTransparency = 0.12
toast.Size = UDim2.fromScale(0.58, 0.07)
toast.Position = UDim2.fromScale(0.21, 0.78)
toast.TextColor3 = Color3.new(1,1,1)
toast.Font = Enum.Font.GothamBold
toast.TextScaled = true
toast.Visible = false
toast.Parent = gui
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 14)
toastCorner.Parent = toast

local function showToast(message: string)
	toast.Text = message
	toast.Visible = true
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.12
	task.delay(2.4, function()
		TweenService:Create(toast, TweenInfo.new(0.35), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		task.wait(0.4)
		toast.Visible = false
	end)
end

remotes.State.OnClientEvent:Connect(function(state)
	local wake = state.wake or 0
	wakeText.Text = ("PLAYGROUND AWAKE: %d%%"):format(wake)
	TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Size = UDim2.fromScale(wake/100, 1)}):Play()
end)

remotes.Round.OnClientEvent:Connect(function(state)
	local phase = state.phase or "RUN"
	local seconds = state.seconds or 0
	roundText.Text = ("%s  •  %02d:%02d"):format(phase, math.floor(seconds/60), seconds%60)
end)

remotes.Toast.OnClientEvent:Connect(showToast)
remotes.Checkpoint.OnClientEvent:Connect(function(index, reward)
	showToast(("CHECKPOINT %d  •  +%d TICKETS"):format(index, reward))
end)
remotes.Eliminated.OnClientEvent:Connect(function()
	showToast("YOU WOKE IT UP.")
end)
