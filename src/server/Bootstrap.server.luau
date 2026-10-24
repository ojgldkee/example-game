--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

-- Boot diagnostics are replicated so the client can tell us exactly which service failed.
local diagnostics = ReplicatedStorage:FindFirstChild("BootDiagnostics")
if diagnostics then
	diagnostics:Destroy()
end
diagnostics = Instance.new("Folder")
diagnostics.Name = "BootDiagnostics"
diagnostics.Parent = ReplicatedStorage

local function report(name: string, ok: boolean, detail: string?)
	local value = Instance.new("StringValue")
	value.Name = name
	value.Value = ok and "OK" or ("ERROR: " .. tostring(detail))
	value.Parent = diagnostics
	if ok then
		print("[BOOT]", name, "OK")
	else
		warn("[BOOT]", name, detail)
	end
end

local remotes = ReplicatedStorage:FindFirstChild(Network.FolderName)
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = Network.FolderName
	remotes.Parent = ReplicatedStorage
end

for _, name in pairs(Network.Events) do
	if not remotes:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
end

for _, name in pairs(Network.Functions) do
	if not remotes:FindFirstChild(name) then
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = remotes
	end
end

report("Remotes", true)

local serverFolder = ServerScriptService:WaitForChild("Server")
local servicesFolder = serverFolder:WaitForChild("services")

-- MapService intentionally boots FIRST. A progression/store bug should never leave
-- the player staring at an empty world.
local ordered = {
	"MapService",
	"PlayerDataService",
	"EntitlementService",
	"SettingsService",
	"QuestService",
	"DailyRewardService",
	"CosmeticService",
	"CheckpointService",
	"ObstacleService",
	"FinishService",
	"WakeService",
	"WakeEventService",
	"MonsterService",
	"PurchaseService",
	"ApiService",
	"RoundService",
}

local services: {[string]: any} = {}
local loadSucceeded: {[string]: boolean} = {}

for _, name in ipairs(ordered) do
	local moduleScript = servicesFolder:FindFirstChild(name)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		loadSucceeded[name] = false
		report(name, false, "ModuleScript missing")
		continue
	end

	local okRequire, moduleOrError = pcall(require, moduleScript)
	if not okRequire then
		loadSucceeded[name] = false
		report(name, false, "require failed: " .. tostring(moduleOrError))
		continue
	end

	local module = moduleOrError
	services[name] = module
	loadSucceeded[name] = true

	if module.Init then
		local okInit, initError = pcall(module.Init, services)
		if not okInit then
			loadSucceeded[name] = false
			report(name, false, "Init failed: " .. tostring(initError))
			continue
		end
	end

	report(name, true)
end

for _, name in ipairs(ordered) do
	if not loadSucceeded[name] then
		continue
	end

	local module = services[name]
	if module and module.Start then
		task.spawn(function()
			local okStart, startError = pcall(module.Start)
			if not okStart then
				report(name .. "_Start", false, tostring(startError))
			else
				report(name .. "_Start", true)
			end
		end)
	end
end

diagnostics:SetAttribute("BootstrapComplete", true)
print("[BOOT] Playground Awake bootstrap complete")
