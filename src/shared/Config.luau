--!strict
local Config = {}

Config.Game = {
	Name = "Playground Awake",
	Version = "0.1.0",
	MinPlayers = 1,
	IntermissionSeconds = 15,
	RoundSeconds = 360,
	FinalChaseSeconds = 90,
	BaseWakePerDeath = 10,
	MaxWake = 100,
	TicketsPerCheckpoint = 5,
	TicketsPerWin = 125,
}

Config.Map = {
	SectionCount = 10,
	SectionLength = 64,
	CourseWidth = 46,
	FloorY = 0,
	StartZ = 24,
}

Config.Monster = {
	Name = "Happy",
	BaseSpeed = 12,
	FinalSpeed = 22,
	RepathSeconds = 0.75,
	AttackDistance = 5.5,
}

-- Replace every 0 with the real ID from Creator Hub before monetization goes live.
Config.GamePasses = {
	VIP = 0,
	DoubleTickets = 0,
	PremiumTrail = 0,
	ExtraCompanionSlot = 0,
}

Config.Products = {
	Revive = 0,
	Tickets500 = 0,
	Tickets1500 = 0,
	SaveTheServer = 0,
	ChaosEvent = 0,
}

Config.ProductRewards = {
	Tickets500 = 500,
	Tickets1500 = 1500,
	SaveTheServerWakeReduction = 20,
}

Config.AnimationIds = {
	HappyIdle = 0,
	HappyWalk = 0,
	HappyRun = 0,
	HappyCrawl = 0,
	HappyLunge = 0,
}

Config.SoundIds = {
	Ambience = 0,
	WakeSting = 0,
	FinalChase = 0,
	MonsterRoar = 0,
}

Config.WakeThresholds = {20, 40, 60, 80, 100}

return Config
