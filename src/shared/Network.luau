--!strict
local Network = {}

Network.FolderName = "PlaygroundRemotes"

Network.Events = {
	State = "State",
	Toast = "Toast",
	Round = "Round",
	Checkpoint = "Checkpoint",
	WakePulse = "WakePulse",
	Eliminated = "Eliminated",
	ShopState = "ShopState",
	Profile = "Profile",
	QuestUpdate = "QuestUpdate",
	DailyReward = "DailyReward",
	CosmeticUpdate = "CosmeticUpdate",
	SettingsUpdate = "SettingsUpdate",
	Spectate = "Spectate",
	MonsterEvent = "MonsterEvent",
	ServerEvent = "ServerEvent",
}

Network.Functions = {
	GetSnapshot = "GetSnapshot",
	ClaimDaily = "ClaimDaily",
	PurchaseCosmetic = "PurchaseCosmetic",
	EquipCosmetic = "EquipCosmetic",
	UpdateSettings = "UpdateSettings",
	RerollQuest = "RerollQuest",\n\tPurchaseUpgrade = "PurchaseUpgrade",
}

return Network
