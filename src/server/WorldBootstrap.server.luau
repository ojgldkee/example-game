--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local status = ReplicatedStorage:FindFirstChild("WorldBootStatus")
if status then status:Destroy() end
status = Instance.new("StringValue")
status.Name = "WorldBootStatus"
status.Value = "STARTING"
status.Parent = ReplicatedStorage

local function emergencyWorld(reason: string)
	warn("[WORLD BOOT] Falling back to emergency world:", reason)

	local old = Workspace:FindFirstChild("GeneratedPlayground")
	if old then old:Destroy() end

	local map = Instance.new("Model")
	map.Name = "GeneratedPlayground"
	map:SetAttribute("EmergencyFallback", true)
	map.Parent = Workspace

	local floor = Instance.new("Part")
	floor.Name = "EmergencyFloor"
	floor.Size = Vector3.new(120, 2, 120)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.SmoothPlastic
	floor.Color = Color3.fromRGB(32, 36, 48)
	floor.Parent = map

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.Position = Vector3.new(0, 3, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(80, 240, 150)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = map

	local sign = Instance.new("Part")
	sign.Name = "BootFailureSign"
	sign.Size = Vector3.new(44, 12, 1)
	sign.Position = Vector3.new(0, 10, -20)
	sign.Anchored = true
	sign.Color = Color3.fromRGB(190, 40, 55)
	sign.Parent = map

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1,1,1)
	label.Text = "WORLD BOOT FALLBACK\n" .. reason
	label.Parent = gui

	map:SetAttribute("BuildComplete", true)
	status.Value = "FALLBACK: " .. reason
end

local serverFolder = ServerScriptService:WaitForChild("Server")
local servicesFolder = serverFolder:WaitForChild("services")
local mapModuleScript = servicesFolder:WaitForChild("MapService")

local okRequire, mapServiceOrError = pcall(require, mapModuleScript)
if not okRequire then
	emergencyWorld("MapService require failed: " .. tostring(mapServiceOrError))
	return
end

local okBuild, buildOrError = pcall(function()
	return mapServiceOrError.Build()
end)

if not okBuild then
	emergencyWorld("MapService.Build failed: " .. tostring(buildOrError))
	return
end

local built = buildOrError
if not built or not built:IsA("Model") then
	emergencyWorld("MapService.Build returned no model")
	return
end

built:SetAttribute("BuildComplete", true)
status.Value = "OK"
print("[WORLD BOOT] GeneratedPlayground ready")
