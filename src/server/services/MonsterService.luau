--!strict
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local MonsterService = {}

local model: Model? = nil
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local tracks: {[string]: AnimationTrack} = {}

local active = false
local rage = false
local finalChase = false
local specialUntil = 0
local frozenUntil = 0
local attackDebounce: {[Player]: number} = {}

local function remotes()
	return ReplicatedStorage:WaitForChild(Network.FolderName)
end

local function stopAllExcept(name: string)
	for trackName, track in pairs(tracks) do
		if trackName ~= name and track.IsPlaying then
			track:Stop(0.15)
		end
	end
end

local function play(name: string, fade: number?)
	local track = tracks[name]
	if not track then
		return
	end

	stopAllExcept(name)
	if not track.IsPlaying then
		track:Play(fade or 0.15)
	end
end

local function safeLoadTrack(name: string, id: number, priority: Enum.AnimationPriority, looped: boolean)
	if id == 0 or not animator then
		return
	end

	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = "rbxassetid://" .. tostring(id)

	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not ok then
		warn(("Failed to load Happy animation %s: %s"):format(name, tostring(trackOrError)))
		return
	end

	local track = trackOrError :: AnimationTrack
	track.Priority = priority
	track.Looped = looped
	tracks[name] = track
end

local function configureImportedRig(imported: Model): (Model, Humanoid, Animator)?
	local cloned = imported:Clone()
	cloned.Name = Config.Monster.Name
	cloned.Parent = Workspace

	local visualRoot = cloned:FindFirstChildWhichIsA("BasePart", true)
	if not visualRoot then
		warn("Imported Happy model has no BasePart")
		cloned:Destroy()
		return nil
	end

	local root = cloned:FindFirstChild("HumanoidRootPart", true)
	if not root or not root:IsA("BasePart") then
		local createdRoot = Instance.new("Part")
		createdRoot.Name = "HumanoidRootPart"
		createdRoot.Size = Vector3.new(3.2, 6.5, 3.2)
		createdRoot.Transparency = 1
		createdRoot.CanCollide = true
		createdRoot.CanQuery = false
		createdRoot.CanTouch = false
		createdRoot.Anchored = false
		createdRoot.CFrame = visualRoot.CFrame
		createdRoot.Parent = cloned
		root = createdRoot

		for _, descendant in ipairs(cloned:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant ~= createdRoot then
				descendant.CanCollide = false
				descendant.Massless = true

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = createdRoot
				weld.Part1 = descendant
				weld.Parent = createdRoot
			end
		end
	end

	cloned.PrimaryPart = root

	local hum = cloned:FindFirstChildOfClass("Humanoid")
	if not hum then
		hum = Instance.new("Humanoid")
		hum.Name = "Humanoid"
		hum.Parent = cloned
	end

	hum.AutoRotate = true
	hum.WalkSpeed = Config.Monster.BaseSpeed
	hum.JumpPower = 45

	local anim = hum:FindFirstChildOfClass("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = hum
	end

	cloned:PivotTo(CFrame.new(0, -100, 0))
	return cloned, hum, anim
end

local function createFallback(): (Model, Humanoid, Animator)
	local m = Instance.new("Model")
	m.Name = Config.Monster.Name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3, 6, 3)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = true
	root.Parent = m

	local torso = Instance.new("Part")
	torso.Name = "TorsoVisual"
	torso.Size = Vector3.new(4.5, 6.5, 3.2)
	torso.Color = Color3.fromRGB(32, 170, 230)
	torso.CanCollide = false
	torso.Massless = true
	torso.CFrame = root.CFrame
	torso.Parent = m

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(5, 5, 5)
	head.Color = Color3.fromRGB(247, 225, 154)
	head.CanCollide = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, 5, 0)
	head.Parent = m

	for _, visiblePart in ipairs({torso, head}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = visiblePart
		weld.Parent = root
	end

	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.AutoRotate = true
	hum.WalkSpeed = Config.Monster.BaseSpeed
	hum.Parent = m

	local anim = Instance.new("Animator")
	anim.Parent = hum

	m.PrimaryPart = root
	m.Parent = Workspace
	m:PivotTo(CFrame.new(0, -100, 0))

	return m, hum, anim
end

local function loadAnimations()
	tracks = {}

	safeLoadTrack("Idle", Config.AnimationIds.HappyIdle, Enum.AnimationPriority.Idle, true)
	safeLoadTrack("Walk", Config.AnimationIds.HappyWalk, Enum.AnimationPriority.Movement, true)
	safeLoadTrack("Run", Config.AnimationIds.HappyRun, Enum.AnimationPriority.Movement, true)
	safeLoadTrack("Crawl", Config.AnimationIds.HappyCrawl, Enum.AnimationPriority.Action, true)
	safeLoadTrack("Lunge", Config.AnimationIds.HappyLunge, Enum.AnimationPriority.Action, false)
	safeLoadTrack("Roar", Config.AnimationIds.HappyRoar, Enum.AnimationPriority.Action, false)
	safeLoadTrack("WallPeek", Config.AnimationIds.HappyWallPeek, Enum.AnimationPriority.Action, false)
	safeLoadTrack("CeilingCrawl", Config.AnimationIds.HappyCeilingCrawl, Enum.AnimationPriority.Action, true)
	safeLoadTrack("Jumpscare", Config.AnimationIds.HappyJumpscare, Enum.AnimationPriority.Action4, false)
end

local function createMonster()
	if model then
		model:Destroy()
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local imported = assets and assets:FindFirstChild(Config.Monster.Name)

	if imported and imported:IsA("Model") then
		local configured = configureImportedRig(imported)
		if configured then
			model, humanoid, animator = configured
		else
			model, humanoid, animator = createFallback()
		end
	else
		model, humanoid, animator = createFallback()
	end

	loadAnimations()
end

local function nearestLivingPlayer(): Player?
	if not model or not model.PrimaryPart then
		return nil
	end

	local best: Player? = nil
	local bestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")

		if root and root:IsA("BasePart") and hum and hum.Health > 0 then
			local distance = (root.Position - model.PrimaryPart.Position).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				best = player
			end
		end
	end

	return best
end

local function spawnBehindPlayers()
	if not model then
		createMonster()
	end

	local map = Workspace:FindFirstChild("GeneratedPlayground")
	local spawn = map and map:FindFirstChild("StartSpawn", true)

	if model and spawn and spawn:IsA("BasePart") then
		model:PivotTo(spawn.CFrame * CFrame.new(0, 4, Config.Monster.SpawnDistanceBehind))
	end
end

local function currentSpeed(): number
	if finalChase then
		return Config.Monster.FinalSpeed
	end
	if rage then
		return Config.Monster.RageSpeed
	end
	return Config.Monster.AwakeSpeed
end

local function attack(target: Player)
	local now = os.clock()
	if attackDebounce[target] and now - attackDebounce[target] < 2 then
		return
	end
	attackDebounce[target] = now

	local character = target.Character
	local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	specialUntil = math.max(specialUntil, now + 0.75)
	frozenUntil = math.max(frozenUntil, now + 0.35)
	play("Jumpscare", 0.05)

	remotes()[Network.Events.MonsterEvent]:FireClient(target, {
		type = "jumpscare",
	})

	task.wait(0.28)
	if targetHumanoid.Health > 0 then
		targetHumanoid.Health = 0
	end
end

local function locomotionAnimation()
	if os.clock() < specialUntil then
		return
	end

	if not active then
		play("Idle")
	elseif finalChase or rage then
		play("Run")
	else
		play("Walk")
	end
end

local function chaseStep()
	if not active or not model or not humanoid or not model.PrimaryPart then
		locomotionAnimation()
		return
	end

	humanoid.WalkSpeed = currentSpeed()
	locomotionAnimation()

	if os.clock() < frozenUntil then
		humanoid:Move(Vector3.zero)
		return
	end

	local target = nearestLivingPlayer()
	local character = target and target.Character
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")

	if not target or not targetRoot or not targetRoot:IsA("BasePart") then
		return
	end

	local distance = (targetRoot.Position - model.PrimaryPart.Position).Magnitude
	if distance <= Config.Monster.AttackDistance then
		attack(target)
		return
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2.8,
		AgentHeight = 8,
		AgentCanJump = true,
		WaypointSpacing = 8,
	})

	local ok = pcall(function()
		path:ComputeAsync(model.PrimaryPart.Position, targetRoot.Position)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()

		for index = 2, math.min(#waypoints, 4) do
			if not active or not humanoid or os.clock() < frozenUntil then
				break
			end

			local waypoint = waypoints[index]
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			humanoid:MoveTo(waypoint.Position)
			local reached = humanoid.MoveToFinished:Wait()
			if not reached then
				break
			end

			if model.PrimaryPart and (targetRoot.Position - model.PrimaryPart.Position).Magnitude <= Config.Monster.AttackDistance then
				attack(target)
				break
			end
		end
	else
		humanoid:MoveTo(targetRoot.Position)
	end
end

local function chaseLoop()
	while true do
		chaseStep()
		task.wait(Config.Monster.RepathSeconds)
	end
end

function MonsterService.Init(_services)
	createMonster()
	task.spawn(chaseLoop)

	Players.PlayerRemoving:Connect(function(player)
		attackDebounce[player] = nil
	end)
end

function MonsterService.SetActive(value: boolean)
	active = value

	if value then
		spawnBehindPlayers()
	else
		if model then
			model:PivotTo(CFrame.new(0, -100, 0))
		end
	end
end

function MonsterService.SetRage(value: boolean)
	rage = value
end

function MonsterService.SetFinalChase(value: boolean)
	finalChase = value
	if value then
		rage = true
	end
end

function MonsterService.PlaySpecial(name: string, duration: number?, freeze: boolean?)
	local track = tracks[name]
	if not track then
		return
	end

	local now = os.clock()
	local length = duration or math.max(track.Length, 0.8)
	specialUntil = math.max(specialUntil, now + length)

	if freeze then
		frozenUntil = math.max(frozenUntil, now + length)
	end

	play(name, 0.08)
end

function MonsterService.Reset()
	active = false
	rage = false
	finalChase = false
	specialUntil = 0
	frozenUntil = 0

	for _, track in pairs(tracks) do
		if track.IsPlaying then
			track:Stop(0.1)
		end
	end

	if model then
		model:PivotTo(CFrame.new(0, -100, 0))
	end
end

return MonsterService
