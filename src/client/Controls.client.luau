--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local WALK_SPEED = 16
local SPRINT_SPEED = 24
local LEAN_AMOUNT = 1.15
local LEAN_TIME = 0.12

local humanoid: Humanoid? = nil
local leanTween: Tween? = nil
local currentLean = 0

local function applyLean(amount: number)
	if not humanoid then return end
	currentLean = amount
	if leanTween then
		leanTween:Cancel()
	end
	leanTween = TweenService:Create(
		humanoid,
		TweenInfo.new(LEAN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CameraOffset = Vector3.new(amount, 0, 0)}
	)
	leanTween:Play()
end

local function bindCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.CameraOffset = Vector3.zero
	currentLean = 0
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	task.spawn(bindCharacter, player.Character)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if UserInputService:GetFocusedTextBox() then return end
	if not humanoid or humanoid.Health <= 0 then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		humanoid.WalkSpeed = SPRINT_SPEED
	elseif input.KeyCode == Enum.KeyCode.Q then
		applyLean(-LEAN_AMOUNT)
	elseif input.KeyCode == Enum.KeyCode.E then
		applyLean(LEAN_AMOUNT)
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if processed then return end
	if not humanoid then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		humanoid.WalkSpeed = WALK_SPEED
	elseif input.KeyCode == Enum.KeyCode.Q and currentLean < 0 then
		applyLean(0)
	elseif input.KeyCode == Enum.KeyCode.E and currentLean > 0 then
		applyLean(0)
	end
end)
