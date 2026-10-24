--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1,1)
label.BackgroundColor3 = Color3.fromRGB(10,12,18)
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Text = "WAKING THE PLAYGROUND..."
label.Parent = gui

local constraint = Instance.new("UITextSizeConstraint")
constraint.MaxTextSize = 42
constraint.MinTextSize = 20
constraint.Parent = label

task.spawn(function()
	local map = Workspace:WaitForChild("GeneratedPlayground", 20)
	if map then
		task.wait(0.35)
		gui:Destroy()
	else
		label.Text = "MAP FAILED TO LOAD — CHECK OUTPUT"
	end
end)
