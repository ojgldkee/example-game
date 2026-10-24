--!strict
local Upgrades = {}

Upgrades.Order = {
	"Armor",
	"Health",
	"Sprint",
	"JumpAssist",
	"TicketBoost",
}

Upgrades.Definitions = {
	Armor = {
		Name = "SOFT LANDING",
		Description = "Take less damage from lasers, sweepers, and crushers.",
		MaxLevel = 5,
		Costs = {180, 420, 850, 1450, 2300},
		DamageReductionPerLevel = 0.07,
	},
	Health = {
		Name = "EXTRA HEARTS",
		Description = "Gain +10 max health per level.",
		MaxLevel = 5,
		Costs = {160, 380, 760, 1300, 2100},
		MaxHealthPerLevel = 10,
	},
	Sprint = {
		Name = "SPRINT TRAINING",
		Description = "Sprint slightly faster. Base route never requires it.",
		MaxLevel = 5,
		Costs = {220, 500, 900, 1500, 2400},
		SprintSpeedPerLevel = 0.8,
	},
	JumpAssist = {
		Name = "SPRING SHOES",
		Description = "Small jump-power boost for extra forgiveness.",
		MaxLevel = 5,
		Costs = {250, 560, 980, 1600, 2500},
		JumpPowerPerLevel = 0.6,
	},
	TicketBoost = {
		Name = "TICKET MAGNET",
		Description = "Earn +5% checkpoint/win tickets per level.",
		MaxLevel = 5,
		Costs = {300, 650, 1100, 1800, 2800},
		TicketMultiplierPerLevel = 0.05,
	},
}

function Upgrades.DefaultLevels()
	local levels = {}
	for _, id in ipairs(Upgrades.Order) do
		levels[id] = 0
	end
	return levels
end

return Upgrades
