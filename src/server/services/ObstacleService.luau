--!strict
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ObstacleService = {}
local originals: {[BasePart]: CFrame} = {}
local touched: {[BasePart]: boolean} = {}

local function hookFallingTile(tile: BasePart)
	originals[tile] = tile.CFrame
	tile.Touched:Connect(function(hit)
		if touched[tile] then return end
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		touched[tile] = true
		task.delay(0.25, function()
			if tile.Parent then
				tile.CanCollide = false
				tile.Transparency = 0.65
			end
		end)
		task.delay(2.2, function()
			if tile.Parent and originals[tile] then
				tile.CFrame = originals[tile]
				tile.CanCollide = true
				tile.Transparency = 0
				touched[tile] = false
			end
		end)
	end)
end

function ObstacleService.Init(_services)
	task.defer(function()
		local map = Workspace:WaitForChild("GeneratedPlayground")
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") then
				if d:GetAttribute("KillPart") then
					d.Touched:Connect(function(hit)
						local hum=hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health>0 then hum.Health=0 end
					end)
				elseif d:GetAttribute("FallingTile") then
					hookFallingTile(d)
				elseif d:GetAttribute("Spinner") then
					originals[d] = d.CFrame
				elseif d:GetAttribute("MoveAxis") then
					originals[d] = d.CFrame
				end
			end
		end

		local start = os.clock()
		RunService.Heartbeat:Connect(function()
			local t = os.clock() - start
			for part, base in pairs(originals) do
				if part.Parent then
					if part:GetAttribute("Spinner") then
						local speed = part:GetAttribute("SpinSpeed") or 45
						part.CFrame = base * CFrame.Angles(0, math.rad(t * speed), 0)
					elseif part:GetAttribute("MoveAxis") then
						local distance = part:GetAttribute("MoveDistance") or 10
						local speed = part:GetAttribute("MoveSpeed") or 1.5
						local offset = math.sin(t * speed) * distance
						local axis = part:GetAttribute("MoveAxis")
						if axis == "X" then
							part.CFrame = base + Vector3.new(offset, 0, 0)
						else
							part.CFrame = base + Vector3.new(0, offset, 0)
						end
					end
				end
			end
		end)
	end)
end

return ObstacleService
