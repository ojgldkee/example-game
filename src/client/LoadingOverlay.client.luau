--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
label.TextWrapped = true
label.Text = "WAKING THE PLAYGROUND..."
label.Parent = gui

local constraint = Instance.new("UITextSizeConstraint")
constraint.MaxTextSize = 42
constraint.MinTextSize = 18
constraint.Parent = label

local function diagnosticText(): string
	local folder = ReplicatedStorage:FindFirstChild("BootDiagnostics")
	if not folder then
		return "SERVER BOOT DIAGNOSTICS DID NOT APPEAR"
	end

	local errors = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("StringValue") and string.sub(child.Value, 1, 5) == "ERROR" then
			table.insert(errors, child.Name .. ": " .. child.Value)
		end
	end

	if #errors == 0 then
		return "MAP MISSING, BUT SERVER REPORTED NO SERVICE ERROR"
	end

	return table.concat(errors, "\n")
end

task.spawn(function()
	local started = os.clock()
	while os.clock() - started < 20 do
		local map = Workspace:FindFirstChild("GeneratedPlayground")
		if map and map:GetAttribute("BuildComplete") == true then
			task.wait(0.25)
			gui:Destroy()
			return
		end
		task.wait(0.2)
	end

	label.Text = "MAP FAILED TO LOAD\n\n" .. diagnosticText()
	label.TextColor3 = Color3.fromRGB(255,105,105)
end)
