--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Network=require(ReplicatedStorage.Shared.Network)

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild(Network.FolderName)
local get=remotes:WaitForChild(Network.Functions.GetSnapshot) :: RemoteFunction

local gui=Instance.new("ScreenGui"); gui.Name="ProfileHUD"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local frame=Instance.new("Frame"); frame.Size=UDim2.fromOffset(255,74); frame.Position=UDim2.fromOffset(18,18); frame.BackgroundColor3=Color3.fromRGB(20,22,30); frame.BackgroundTransparency=.08; frame.Parent=gui
local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,16); c.Parent=frame
local tickets=Instance.new("TextLabel"); tickets.Text="150 TICKETS"; tickets.BackgroundTransparency=1; tickets.Size=UDim2.new(1,-20,.48,0); tickets.Position=UDim2.fromOffset(10,6); tickets.Font=Enum.Font.GothamBlack; tickets.TextScaled=true; tickets.TextColor3=Color3.fromRGB(255,220,70); tickets.TextXAlignment=Enum.TextXAlignment.Left; tickets.Parent=frame
local level=Instance.new("TextLabel"); level.Text="LEVEL 1   •   0 WINS"; level.BackgroundTransparency=1; level.Size=UDim2.new(1,-20,.4,0); level.Position=UDim2.new(0,10,.52,0); level.Font=Enum.Font.GothamBold; level.TextScaled=true; level.TextColor3=Color3.new(1,1,1); level.TextXAlignment=Enum.TextXAlignment.Left; level.Parent=frame

local function render(p)
	if not p then return end
	tickets.Text=("%s TICKETS"):format(tostring(p.Tickets or 0))
	local best = p.BestTime or 0
	if best > 0 then
		level.Text=("LV %d • %d WINS • BEST %.2fs"):format(p.Level or 1,p.Wins or 0,best)
	else
		level.Text=("LV %d • %d WINS • NO BEST YET"):format(p.Level or 1,p.Wins or 0)
	end
end
remotes.Profile.OnClientEvent:Connect(render)
task.spawn(function()
	task.wait(2)
	local ok,res=pcall(function() return get:InvokeServer() end)
	if ok then render(res) end
end)
