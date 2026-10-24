--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)

local PlayerDataService = {}
local store = DataStoreService:GetDataStore("PlaygroundAwake_PlayerData_v2")
local cache: {[Player]: any} = {}
local dirty: {[Player]: boolean} = {}

local DEFAULT = {
	Schema = 3,
	Wins = 0,
	Tickets = Config.Economy.StartingTickets,
	XP = 0,
	Level = 1,
	Revives = 0,
	Checkpoint = 0,
	RoundsPlayed = 0,
	BestWakeEscaped = 0,
	TotalDeaths = 0,
	TotalCheckpoints = 0,
	Receipts = {},
	Upgrades = Upgrades.DefaultLevels(),
	Daily = {Last=-999999, Streak=0},
	QuestState = {DateKey="", Active={}, Stats={}},
	Cosmetics = {
		Owned = {none=true, rookie=true, poof=true},
		Equipped = {Trails="none", Titles="rookie", DeathEffects="poof"},
	},
	Settings = {
		Music=true,
		SFX=true,
		CameraShake=true,
		ReducedFlashes=false,
		PerformanceMode=false,
		AutoSpectate=true,
	},
}

local function deepClone(value)
	if typeof(value) ~= "table" then return value end
	local out = {}
	for k,v in pairs(value) do out[k] = deepClone(v) end
	return out
end

local function mergeDefaults(target, defaults)
	for k,v in pairs(defaults) do
		if target[k] == nil then
			target[k] = deepClone(v)
		elseif typeof(v) == "table" and typeof(target[k]) == "table" then
			mergeDefaults(target[k], v)
		end
	end
	return target
end

local function xpForNext(level: number): number
	return math.floor(Config.Progression.BaseXP * (Config.Progression.XPGrowth ^ math.max(0, level - 1)))
end

local function recalcLevel(data)
	local guard = 0
	while data.Level < Config.Progression.MaxLevel and data.XP >= xpForNext(data.Level) and guard < 200 do
		data.XP -= xpForNext(data.Level)
		data.Level += 1
		guard += 1
	end
end

local function snapshot(player: Player)
	local data = cache[player]
	if not data then return nil end
	return {
		Wins=data.Wins,
		Tickets=data.Tickets,
		XP=data.XP,
		Level=data.Level,
		XPToNext=xpForNext(data.Level),
		Revives=data.Revives,
		RoundsPlayed=data.RoundsPlayed,
		BestWakeEscaped=data.BestWakeEscaped,
		TotalDeaths=data.TotalDeaths,
		TotalCheckpoints=data.TotalCheckpoints,
		Daily=data.Daily,
		QuestState=data.QuestState,
		Cosmetics=data.Cosmetics,
		Settings=data.Settings,
		Upgrades=data.Upgrades,
	}
end

local function pushProfile(player: Player)
	local folder = ReplicatedStorage:FindFirstChild(Network.FolderName)
	local ev = folder and folder:FindFirstChild(Network.Events.Profile)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(player, snapshot(player))
	end
end

local function loadPlayer(player: Player)
	local key = "u_" .. player.UserId
	local ok, result = pcall(function() return store:GetAsync(key) end)
	local data
	if ok and type(result) == "table" then
		data = mergeDefaults(result, deepClone(DEFAULT))
	else
		data = deepClone(DEFAULT)
	end
	cache[player] = data
	dirty[player] = false
	task.defer(pushProfile, player)
end

local function savePlayer(player: Player)
	local data = cache[player]
	if not data then return end
	local key = "u_" .. player.UserId
	local payload = deepClone(data)
	local ok, err = pcall(function()
		store:UpdateAsync(key, function()
			return payload
		end)
	end)
	if ok then dirty[player] = false else warn("Save failed", player.UserId, err) end
end

function PlayerDataService.Init(_services)
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		cache[player] = nil
		dirty[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
	task.spawn(function()
		while true do
			task.wait(Config.Game.AutosaveSeconds)
			for _,player in ipairs(Players:GetPlayers()) do
				if dirty[player] then task.spawn(savePlayer, player) end
			end
		end
	end)
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do savePlayer(player) end
	end)
end

function PlayerDataService.Get(player: Player) return cache[player] end
function PlayerDataService.GetSnapshot(player: Player) return snapshot(player) end

function PlayerDataService.Add(player: Player, key: string, amount: number)
	local data = cache[player]
	if not data then return end
	data[key] = (data[key] or 0) + amount
	if key == "XP" then recalcLevel(data) end
	dirty[player] = true
	pushProfile(player)
end

function PlayerDataService.Set(player: Player, key: string, value: any)
	local data = cache[player]
	if not data then return end
	data[key] = value
	dirty[player] = true
	pushProfile(player)
end

function PlayerDataService.MarkDirty(player: Player)
	if cache[player] then dirty[player] = true end
end

function PlayerDataService.Save(player: Player) savePlayer(player) end

return PlayerDataService
