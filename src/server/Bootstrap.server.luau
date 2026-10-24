--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

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

local servicesFolder = ServerScriptService.Server:WaitForChild("services")
local ordered = {
	"PlayerDataService",
	"MapService",
	"CheckpointService",
	"ObstacleService",
	"FinishService",
	"WakeService",
	"MonsterService",
	"PurchaseService",
	"RoundService",
}

local services = {}
for _, name in ipairs(ordered) do
	local module = require(servicesFolder:WaitForChild(name))
	services[name] = module
	if module.Init then
		module.Init(services)
	end
end

for _, name in ipairs(ordered) do
	local module = services[name]
	if module.Start then
		task.spawn(module.Start)
	end
end
