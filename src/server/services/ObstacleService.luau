--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ObstacleService = {}
local services

local originals: {[BasePart]: CFrame} = {}
local fallingTouched: {[BasePart]: boolean} = {}
local hazardCooldown: {[Player]: number} = {}
local damageCooldown: {[Humanoid]: number} = {}
local conveyorCooldown: {[Humanoid]: number} = {}
local bounceCooldown: {[Humanoid]: number} = {}
local speedCooldown: {[Humanoid]: number} = {}
local blinkParts: {BasePart} = {}

local function findRespawnCFrame(player: Player): CFrame?
	local data = services.PlayerDataService.Get(player)
	local map = Workspace:FindFirstChild("GeneratedPlayground")
	if not map then return nil end

	local checkpointIndex = data and data.Checkpoint or 0
	if checkpointIndex > 0 then
		for _, descendant in ipairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("CheckpointIndex") == checkpointIndex then
				return descendant.CFrame + Vector3.new(0, Config.Obby.CheckpointLift, 0)
			end
		end
	end

	local spawn = map:FindFirstChild("StartSpawn", true)
	if spawn and spawn:IsA("BasePart") then
		return spawn.CFrame + Vector3.new(0, Config.Obby.CheckpointLift, 0)
	end
	return nil
end

local function getHumanoidFromHit(hit: BasePart): (Humanoid?, Model?)
	local current: Instance? = hit
	for _=1,3 do
		if not current then break end
		if current:IsA("Model") then
			local humanoid = current:FindFirstChildOfClass("Humanoid")
			if humanoid then return humanoid, current end
		end
		current = current.Parent
	end
	return nil, nil
end

local function upgradedDamage(player: Player?, rawDamage: number): number
	if not player or not services.UpgradeService then
		return rawDamage
	end
	return math.max(1, math.floor(rawDamage * services.UpgradeService.HazardMultiplier(player) + 0.5))
end

local function hookHazard(hazard: BasePart)
	hazard.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local now = os.clock()
		if hazardCooldown[player] and now - hazardCooldown[player] < Config.Obby.HazardGraceSeconds then
			return
		end
		hazardCooldown[player] = now

		-- Deep red death floor is always lethal. Armor applies to lasers/crushers,
		-- not falling off the course.
		humanoid.Health = 0
	end)
end

local function hookDamagePart(obstacle: BasePart)
	obstacle.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if damageCooldown[humanoid] and now - damageCooldown[humanoid] < Config.Obby.LaserGraceSeconds then
			return
		end
		damageCooldown[humanoid] = now

		local player = Players:GetPlayerFromCharacter(character)
		local raw = obstacle:GetAttribute("Damage") or Config.Obby.LaserDamage
		humanoid:TakeDamage(upgradedDamage(player, raw))

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local away = root.Position - obstacle.Position
			local horizontal = Vector3.new(away.X,0,away.Z)
			if horizontal.Magnitude > 0.05 then
				root.AssemblyLinearVelocity += horizontal.Unit * 10 + Vector3.new(0,7,0)
			end
		end
	end)
end

local function hookFallingTile(tile: BasePart)
	originals[tile] = tile.CFrame

	tile.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or fallingTouched[tile] then return end

		fallingTouched[tile] = true
		local delayTime = tile:GetAttribute("FallDelay") or 0.62

		task.spawn(function()
			for _=1,3 do
				if not tile.Parent then return end
				tile.Transparency = 0.28
				task.wait(delayTime/6)
				if not tile.Parent then return end
				tile.Transparency = 0
				task.wait(delayTime/6)
			end

			if tile.Parent then
				tile.CanCollide = false
				tile.Transparency = 0.78
			end

			task.wait(1.75)

			if tile.Parent and originals[tile] then
				tile.CFrame = originals[tile]
				tile.CanCollide = true
				tile.Transparency = 0
				fallingTouched[tile] = false
			end
		end)
	end)
end

local function hookBouncePad(pad: BasePart)
	pad.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if bounceCooldown[humanoid] and now - bounceCooldown[humanoid] < 0.55 then return end
		bounceCooldown[humanoid] = now

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local bounce = pad:GetAttribute("BounceVelocity") or Config.Obby.BounceVelocity
			root.AssemblyLinearVelocity = Vector3.new(
				root.AssemblyLinearVelocity.X,
				bounce,
				math.max(root.AssemblyLinearVelocity.Z, 15)
			)
		end
	end)
end

local function hookConveyor(conveyor: BasePart)
	conveyor.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if conveyorCooldown[humanoid] and now - conveyorCooldown[humanoid] < 0.18 then return end
		conveyorCooldown[humanoid] = now

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.AssemblyLinearVelocity += Vector3.new(0,0,conveyor:GetAttribute("ConveyorSpeed") or 0)
		end
	end)
end

local function hookSpeedPad(pad: BasePart)
	pad.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if speedCooldown[humanoid] and now - speedCooldown[humanoid] < 0.6 then return end
		speedCooldown[humanoid] = now

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local boost = pad:GetAttribute("SpeedBoost") or Config.Obby.SpeedPadBoost
			local forward = root.CFrame.LookVector
			root.AssemblyLinearVelocity += Vector3.new(forward.X*boost,5,forward.Z*boost)
		end
	end)
end

local function register(part: BasePart)
	if part:GetAttribute("HazardPart") then hookHazard(part) end
	if part:GetAttribute("DamagePart") then hookDamagePart(part) end
	if part:GetAttribute("FallingTile") then hookFallingTile(part) end
	if part:GetAttribute("BouncePad") then hookBouncePad(part) end
	if part:GetAttribute("Conveyor") then hookConveyor(part) end
	if part:GetAttribute("SpeedPad") then hookSpeedPad(part) end
	if part:GetAttribute("BlinkPlatform") then table.insert(blinkParts, part) end

	if part:GetAttribute("Spinner") or part:GetAttribute("MoveAxis") then
		originals[part] = part.CFrame
	end
end

function ObstacleService.Init(allServices)
	services = allServices

	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")

		for _, descendant in ipairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") then
				register(descendant)
			end
		end

		map.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				register(descendant)
			end
		end)

		local start = os.clock()
		RunService.Heartbeat:Connect(function()
			local t = os.clock() - start

			for movingPart, base in pairs(originals) do
				if not movingPart.Parent then
					continue
				end

				if movingPart:GetAttribute("Spinner") then
					local speed = movingPart:GetAttribute("SpinSpeed") or 28
					movingPart.CFrame = base * CFrame.Angles(0,math.rad(t*speed),0)
				elseif movingPart:GetAttribute("MoveAxis") then
					local distance = movingPart:GetAttribute("MoveDistance") or 4
					local speed = movingPart:GetAttribute("MoveSpeed") or .9
					local offset = math.sin(t*speed) * distance
					local axis = movingPart:GetAttribute("MoveAxis")

					if axis=="X" then
						movingPart.CFrame = base + Vector3.new(offset,0,0)
					elseif axis=="Y" then
						movingPart.CFrame = base + Vector3.new(0,offset,0)
					else
						movingPart.CFrame = base + Vector3.new(0,0,offset)
					end
				end
			end

			local cycle = Config.Obby.BlinkOnSeconds + Config.Obby.BlinkOffSeconds
			for _, blink in ipairs(blinkParts) do
				if blink.Parent then
					local phase = blink:GetAttribute("BlinkPhase") or 0
					local localTime = (t + phase) % cycle
					local on = localTime < Config.Obby.BlinkOnSeconds
					blink.CanCollide = on
					blink.Transparency = on and 0 or 0.82
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		hazardCooldown[player] = nil
	end)
end

return ObstacleService
