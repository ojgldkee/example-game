--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local humanoid: Humanoid? = nil
local leanTween: Tween? = nil
local fovTween: Tween? = nil
local currentLean = 0
local sprinting = false
local lastGroundedAt = 0
local jumpQueuedUntil = 0

local COYOTE_TIME = 0.13
local JUMP_BUFFER = 0.13
local LEAN_AMOUNT = 1.05
local LEAN_TIME = 0.12
local BASE_FOV = 70
local SPRINT_FOV = 76\n\nlocal function sprintSpeed(): number\n\tlocal value = player:GetAttribute("ObbySprintSpeed")\n\treturn typeof(value)=="number" and value or Config.Movement.SprintSpeed\nend\n\nlocal function jumpPower(): number\n\tlocal value = player:GetAttribute("ObbyJumpPower")\n\treturn typeof(value)=="number" and value or Config.Movement.JumpPower\nend

local function tweenFov(target: number)
	if not camera then return end
	if fovTween then fovTween:Cancel() end
	fovTween = TweenService:Create(
		camera,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = target}
	)
	fovTween:Play()
end

local function setSprint(value: boolean)
	sprinting = value
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = value and sprintSpeed() or Config.Movement.WalkSpeed
	end
	tweenFov(value and SPRINT_FOV or BASE_FOV)
end

local function applyLean(amount: number)
	if not humanoid then return end
	currentLean = amount

	if leanTween then
		leanTween:Cancel()
	end

	leanTween = TweenService:Create(
		humanoid,
		TweenInfo.new(LEAN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CameraOffset = Vector3.new(amount,0,0)}
	)
	leanTween:Play()
end

local function bindCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.UseJumpPower = true
	humanoid.JumpPower = jumpPower()
	humanoid.WalkSpeed = Config.Movement.WalkSpeed
	humanoid.CameraOffset = Vector3.zero
	currentLean = 0
	sprinting = false
	lastGroundedAt = os.clock()
	jumpQueuedUntil = 0

	if camera then
		camera.FieldOfView = BASE_FOV
	end
end

local function requestJump()
	if not humanoid or humanoid.Health <= 0 then return end

	local now = os.clock()
	jumpQueuedUntil = now + JUMP_BUFFER

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local withinCoyote = now - lastGroundedAt <= COYOTE_TIME

	if grounded or withinCoyote then
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		jumpQueuedUntil = 0
	end
end

local function sprintAction(_name: string, state: Enum.UserInputState, _input: InputObject)
	if state == Enum.UserInputState.Begin then
		setSprint(true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		setSprint(false)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
	"PlaygroundSprint",
	sprintAction,
	true,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.ButtonL3
)
ContextActionService:SetTitle("PlaygroundSprint", "SPRINT")
ContextActionService:SetPosition("PlaygroundSprint", UDim2.new(1,-160,1,-150))

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	task.spawn(bindCharacter, player.Character)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if UserInputService:GetFocusedTextBox() then return end
	if not humanoid or humanoid.Health <= 0 then return end

	if input.KeyCode == Enum.KeyCode.Space then
		requestJump()
	elseif input.KeyCode == Enum.KeyCode.Q then
		applyLean(-LEAN_AMOUNT)
	elseif input.KeyCode == Enum.KeyCode.E then
		applyLean(LEAN_AMOUNT)
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if processed then return end
	if not humanoid then return end

	if input.KeyCode == Enum.KeyCode.Q and currentLean < 0 then
		applyLean(0)
	elseif input.KeyCode == Enum.KeyCode.E and currentLean > 0 then
		applyLean(0)
	end
end)

RunService.RenderStepped:Connect(function()
	if not humanoid or humanoid.Health <= 0 then return end

	local now = os.clock()
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

	if grounded then
		lastGroundedAt = now

		if jumpQueuedUntil > now then
			humanoid.Jump = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			jumpQueuedUntil = 0
		end
	elseif jumpQueuedUntil > 0 and jumpQueuedUntil <= now then
		jumpQueuedUntil = 0
	end

	-- Reassert calibrated movement if another Roblox script changes it.
	local targetSpeed = sprinting and sprintSpeed() or Config.Movement.WalkSpeed
	if math.abs(humanoid.WalkSpeed - targetSpeed) > 0.1 then
		humanoid.WalkSpeed = targetSpeed
	end
	if math.abs(humanoid.JumpPower - Config.Movement.JumpPower) > 0.1 then
		humanoid.JumpPower = Config.Movement.JumpPower
	end
end)
