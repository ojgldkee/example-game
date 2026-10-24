--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.Shared.Network)
local remotes = ReplicatedStorage:WaitForChild(Network.FolderName)

local blur = Lighting:FindFirstChild("WakeBlur") or Instance.new("BlurEffect")
blur.Name = "WakeBlur"
blur.Size = 0
blur.Parent = Lighting

local cc = Lighting:FindFirstChild("WakeColor") or Instance.new("ColorCorrectionEffect")
cc.Name = "WakeColor"
cc.Contrast = 0
cc.Saturation = 0
cc.TintColor = Color3.new(1,1,1)
cc.Parent = Lighting

remotes.WakePulse.OnClientEvent:Connect(function(wake)
	local strength = wake / 100
	TweenService:Create(blur, TweenInfo.new(0.12), {Size = 4 + 8 * strength}):Play()
	TweenService:Create(cc, TweenInfo.new(0.25), {
		Contrast = 0.05 + 0.25 * strength,
		Saturation = -0.1 * strength,
		TintColor = Color3.fromRGB(255, 255 - math.floor(90*strength), 255 - math.floor(90*strength)),
	}):Play()
	task.delay(0.22, function()
		TweenService:Create(blur, TweenInfo.new(0.4), {Size = 0}):Play()
	end)
end)
