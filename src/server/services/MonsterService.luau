--!strict
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local MonsterService = {}
local model: Model? = nil
local humanoid: Humanoid? = nil
local active = false
local rage = false
local services

local function createMonster()
	if model then model:Destroy() end
	local m = Instance.new("Model")
	m.Name = Config.Monster.Name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3, 5, 2)
	root.Color = Color3.fromRGB(230, 230, 230)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = false
	root.CanCollide = true
	root.Parent = m

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(4, 4, 4)
	head.Color = Color3.fromRGB(255, 245, 210)
	head.CFrame = root.CFrame * CFrame.new(0, 4.2, 0)
	head.Parent = m

	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.WalkSpeed = Config.Monster.BaseSpeed
	hum.AutoRotate = true
	hum.Parent = m

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root

	m.PrimaryPart = root
	m.Parent = Workspace
	m:PivotTo(CFrame.new(0, -100, 0))

	model = m
	humanoid = hum
	return m
end

local function nearestLivingPlayer(): Player?
	if not model or not model.PrimaryPart then return nil end
	local best: Player? = nil
	local bestDist = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local dist = (hrp.Position - model.PrimaryPart.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = player
			end
		end
	end
	return best
end

local function spawnAtBack()
	if not model then createMonster() end
	local map = Workspace:FindFirstChild("GeneratedPlayground")
	local spawn = map and map:FindFirstChild("StartSpawn", true)
	if model and spawn and spawn:IsA("BasePart") then
		model:PivotTo(spawn.CFrame * CFrame.new(0, 4, 18))
	end
end

local function chaseLoop()
	while true do
		if active and model and humanoid and model.PrimaryPart then
			humanoid.WalkSpeed = rage and Config.Monster.FinalSpeed or Config.Monster.BaseSpeed
			local target = nearestLivingPlayer()
			local char = target and target.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local path = PathfindingService:CreatePath({
					AgentRadius = 2.5,
					AgentHeight = 7,
					AgentCanJump = true,
				})
				local ok = pcall(function()
					path:ComputeAsync(model.PrimaryPart.Position, hrp.Position)
				end)
				if ok and path.Status == Enum.PathStatus.Success then
					for _, waypoint in ipairs(path:GetWaypoints()) do
						if not active or not humanoid then break end
						if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
						humanoid:MoveTo(waypoint.Position)
						humanoid.MoveToFinished:Wait()
						if (hrp.Position - model.PrimaryPart.Position).Magnitude <= Config.Monster.AttackDistance then
							local targetHum = char and char:FindFirstChildOfClass("Humanoid")
							if targetHum then targetHum.Health = 0 end
							break
						end
					end
				else
					humanoid:MoveTo(hrp.Position)
				end
			end
		end
		task.wait(Config.Monster.RepathSeconds)
	end
end

function MonsterService.Init(allServices)
	services = allServices
	createMonster()
	task.spawn(chaseLoop)
end

function MonsterService.SetActive(value: boolean)
	active = value
	if value then
		spawnAtBack()
	elseif model then
		model:PivotTo(CFrame.new(0, -100, 0))
	end
end

function MonsterService.SetRage(value: boolean)
	rage = value
end

function MonsterService.Reset()
	active = false
	rage = false
	if model then model:PivotTo(CFrame.new(0, -100, 0)) end
end

return MonsterService
