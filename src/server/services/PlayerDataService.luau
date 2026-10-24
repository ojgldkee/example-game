--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataService = {}
local store = DataStoreService:GetDataStore("PlaygroundAwake_PlayerData_v1")
local cache: {[Player]: any} = {}

local DEFAULT = {
	Wins = 0,
	Tickets = 0,
	Revives = 0,
	Checkpoint = 0,
	Receipts = {},
}

local function cloneDefault()
	local t = {}
	for k, v in pairs(DEFAULT) do
		t[k] = typeof(v) == "table" and {} or v
	end
	return t
end

local function loadPlayer(player: Player)
	local key = "u_" .. player.UserId
	local ok, result = pcall(function()
		return store:GetAsync(key)
	end)
	if ok and type(result) == "table" then
		local data = cloneDefault()
		for k, v in pairs(result) do
			data[k] = v
		end
		cache[player] = data
	else
		cache[player] = cloneDefault()
	end
end

local function savePlayer(player: Player)
	local data = cache[player]
	if not data then return end
	local key = "u_" .. player.UserId
	pcall(function()
		store:UpdateAsync(key, function()
			return data
		end)
	end)
end

function PlayerDataService.Init(_services)
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		cache[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPlayer, player)
	end
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
	end)
end

function PlayerDataService.Get(player: Player)
	return cache[player]
end

function PlayerDataService.Add(player: Player, key: string, amount: number)
	local data = cache[player]
	if not data then return end
	data[key] = (data[key] or 0) + amount
end

function PlayerDataService.Set(player: Player, key: string, value: any)
	local data = cache[player]
	if data then data[key] = value end
end

function PlayerDataService.Save(player: Player)
	savePlayer(player)
end

return PlayerDataService
