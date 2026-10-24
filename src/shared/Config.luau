--!strict
local Config = {}

Config.Game = {
	Name = "Playground Awake",
	Version = "1.2.0-obby-overhaul",
	PlaceTag = "production-candidate",
	MinPlayers = 1,
	MaxPlayers = 12,
	IntermissionSeconds = 12,
	RoundSeconds = 720,
	FinalChaseSeconds = 75,
	RespawnDelay = 2.25,
	BaseWakePerDeath = 7,
	MaxWake = 100,
	TicketsPerCheckpoint = 12,
	TicketsPerWin = 250,
	XPPerCheckpoint = 12,
	XPPerWin = 160,
	AutosaveSeconds = 60,
}

Config.Progression = {
	MaxLevel = 100,
	BaseXP = 140,
	XPGrowth = 1.14,
	DailyStreakCap = 7,
	QuestSlots = 3,
}

Config.Movement = {
	WalkSpeed = 16,
	SprintSpeed = 22,
	JumpPower = 52,
	Gravity = 196.2,
	-- v=52, g=196.2 => airtime ~= 0.53s.
	-- At WalkSpeed 16, theoretical flat travel ~= 8.48 studs.
	-- Required route clear gaps stay between 3.4 and 5.2 studs.
	SafeWalkClearGap = 5.2,
	BeginnerGap = 3.8,
	StandardGap = 4.4,
	HardGap = 5.0,
	MaxOptionalSprintGap = 7.0,
}

Config.Obby = {
	HazardY = -8,
	EarlyHazardDamage = 28,
	MidHazardDamage = 36,
	LateHazardDamage = 44,
	HazardGraceSeconds = 0.9,
	LaserDamage = 22,
	LaserGraceSeconds = 0.7,
	BounceVelocity = 60,
	CheckpointLift = 4.5,
	FallResetDelay = 0.08,
	BlinkOnSeconds = 1.45,
	BlinkOffSeconds = 0.8,
	SpeedPadBoost = 28,
}

Config.Map = {
	SectionCount = 15,
	SectionLength = 96,
	CourseWidth = 54,
	FloorY = 0,
	StartZ = 50,
	WallHeight = 34,
	CeilingHeight = 35,
	LobbyLength = 64,
	SeedRotationMinutes = 30,
}

Config.Monster = {
	Name = "Happy",
	BaseSpeed = 12.5,
	AwakeSpeed = 15.5,
	RageSpeed = 19,
	FinalSpeed = 23.5,
	RepathSeconds = 0.55,
	AttackDistance = 5.8,
	SpawnDistanceBehind = 28,
	HeadTrackDistance = 100,
}

Config.Wake = {
	Thresholds = {10, 20, 35, 50, 65, 80, 90, 100},
	EventCooldown = 9,
	RandomEventMinWake = 20,
	RandomEventIntervalMin = 18,
	RandomEventIntervalMax = 34,
}

Config.Economy = {
	StartingTickets = 150,
	VIPTicketMultiplier = 1.25,
	DoubleTicketsMultiplier = 2,
	DailyBaseTickets = 120,
	DailyStreakBonus = 35,
	CosmeticRefundPercent = 0,
	UpgradeTicketBonusPerLevel = 0.05,
}

-- Replace zero IDs after creating products/passes in Creator Hub.
Config.GamePasses = {
	VIP = 0,
	DoubleTickets = 0,
	PremiumTrail = 0,
	ExtraCompanionSlot = 0,
	ExclusiveEmotes = 0,
	GoldenName = 0,
	CheckpointAura = 0,
	SpeedCoil = 0,
	GravityCoil = 0,
}

Config.Products = {
	Revive = 0,
	ReviveTeam = 0,
	SkipStage = 0,
	Tickets500 = 0,
	Tickets1500 = 0,
	Tickets5000 = 0,
	SaveTheServer = 0,
	ChaosEvent = 0,
	WakeSkip = 0,
	QuestReroll = 0,
	LowGravityServer = 0,
	TinyServer = 0,
	BlackoutServer = 0,
}

Config.ProductRewards = {
	Tickets500 = 500,
	Tickets1500 = 1500,
	Tickets5000 = 5000,
	SaveTheServerWakeReduction = 18,
	ChaosWakeIncrease = 12,
	WakeSkipIncrease = 20,
}

Config.AnimationIds = {
	HappyIdle = 0,
	HappyWalk = 0,
	HappyRun = 0,
	HappyCrawl = 0,
	HappyLunge = 0,
	HappyRoar = 0,
	HappyWallPeek = 0,
	HappyCeilingCrawl = 0,
	HappyJumpscare = 0,
	PlayerVictory = 0,
}

Config.SoundIds = {
	Ambience = 0,
	WakeSting = 0,
	Heartbeat = 0,
	FinalChase = 0,
	MonsterRoar = 0,
	Checkpoint = 0,
	Win = 0,
	Death = 0,
	ShopOpen = 0,
}

Config.Analytics = {
	Enabled = true,
	LogPurchases = true,
	LogRoundFunnel = true,
	LogWakeDeaths = true,
}

Config.Security = {
	MaxRemoteCallsPerSecond = 12,
	MaxShopPromptsPerMinute = 8,
	MaxCheckpointJump = 1,
}

return Config
