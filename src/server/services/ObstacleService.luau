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

local function findRespawnCFrame(player: Player): CFrame?
	local data = services and services.PlayerDataService and services.PlayerDataService.Get(player)
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
	local character = hit.Parent
	if not character then return nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then return humanoid, character end

	if character.Parent then
		local maybeHumanoid = character.Parent:FindFirstChildOfClass("Humanoid")
		if maybeHumanoid and character.Parent:IsA("Model") then
			return maybeHumanoid, character.Parent
		end
	end

	return nil, nil
end

local function hookHazard(part: BasePart)
	part.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local now = os.clock()
		if hazardCooldown[player] and now - hazardCooldown[player] < Config.Obby.HazardGraceSeconds then
			return
		end
		hazardCooldown[player] = now

		local damage = part:GetAttribute("HazardDamage") or Config.Obby.EarlyHazardDamage
		humanoid:TakeDamage(damage)

		-- Falling off a platform should cost health and reset progress position,
		-- not instantly murder the player from a tiny toe touch.
		if humanoid.Health > 0 then
			local respawnCFrame = findRespawnCFrame(player)
			if respawnCFrame then
				task.defer(function()
					if character.Parent and humanoid.Health > 0 then
						character:PivotTo(respawnCFrame)
					end
				end)
			end
		end
	end)
end

local function hookDamagePart(part: BasePart)
	part.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if damageCooldown[humanoid] and now - damageCooldown[humanoid] < Config.Obby.LaserGraceSeconds then
			return
		end
		damageCooldown[humanoid] = now

		local damage = part:GetAttribute("Damage") or Config.Obby.LaserDamage
		humanoid:TakeDamage(damage)

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local away = root.Position - part.Position
			if away.Magnitude > 0.05 then
				local horizontal = Vector3.new(away.X,0,away.Z).Unit
				root.AssemblyLinearVelocity += horizontal * 12 + Vector3.new(0,8,0)
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
		local delayTime = tile:GetAttribute("FallDelay") or 0.55

		-- Flash warning before dropping.
		task.spawn(function()
			for _=1,3 do
				if not tile.Parent then return end
				tile.Transparency = 0.32
				task.wait(delayTime/6)
				if not tile.Parent then return end
				tile.Transparency = 0
				task.wait(delayTime/6)
			end

			if tile.Parent then
				tile.CanCollide = false
				tile.Transparency = 0.72
			end

			task.wait(1.8)

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
		if bounceCooldown[humanoid] and now - bounceCooldown[humanoid] < 0.6 then return end
		bounceCooldown[humanoid] = now

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local bounce = pad:GetAttribute("BounceVelocity") or Config.Obby.BounceVelocity
			root.AssemblyLinearVelocity = Vector3.new(
				root.AssemblyLinearVelocity.X,
				bounce,
				math.max(root.AssemblyLinearVelocity.Z, 12)
			)
		end
	end)
end

local function hookConveyor(part: BasePart)
	part.Touched:Connect(function(hit)
		local humanoid, character = getHumanoidFromHit(hit)
		if not humanoid or not character or humanoid.Health <= 0 then return end

		local now = os.clock()
		if conveyorCooldown[humanoid] and now - conveyorCooldown[humanoid] < 0.2 then return end
		conveyorCooldown[humanoid] = now

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local speed = part:GetAttribute("ConveyorSpeed") or 0
			root.AssemblyLinearVelocity += Vector3.new(0,0,speed)
		end
	end)
end

function ObstacleService.Init(allServices)
	services = allServices

	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")

		for _, descendant in ipairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if descendant:GetAttribute("HazardPart") then
					hookHazard(descendant)
				end
				if descendant:GetAttribute("DamagePart") then
					hookDamagePart(descendant)
				end
				if descendant:GetAttribute("FallingTile") then
					hookFallingTile(descendant)
				end
				if descendant:GetAttribute("BouncePad") then
					hookBouncePad(descendant)
				end
				if descendant:GetAttribute("Conveyor") then
					hookConveyor(descendant)
				end
				if descendant:GetAttribute("Spinner") or descendant:GetAttribute("MoveAxis") then
					originals[descendant] = descendant.CFrame
				end
			end
		end

		local start = os.clock()
		RunService.Heartbeat:Connect(function()
			local t = os.clock() - start

			for movingPart, base in pairs(originals) do
				if not movingPart.Parent then
					continue
				end

				if movingPart:GetAttribute("Spinner") then
					local speed = movingPart:GetAttribute("SpinSpeed") or 28
					movingPart.CFrame = base * CFrame.Angles(0, math.rad(t * speed), 0)
				elseif movingPart:GetAttribute("MoveAxis") then
					local distance = movingPart:GetAttribute("MoveDistance") or 4
					local speed = movingPart:GetAttribute("MoveSpeed") or 0.9
					local offset = math.sin(t * speed) * distance
					local axis = movingPart:GetAttribute("MoveAxis")

					if axis == "X" then
						movingPart.CFrame = base + Vector3.new(offset,0,0)
					elseif axis == "Y" then
						movingPart.CFrame = base + Vector3.new(0,offset,0)
					else
						movingPart.CFrame = base + Vector3.new(0,0,offset)
					end
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		hazardCooldown[player] = nil
	end)
end

return ObstacleService
