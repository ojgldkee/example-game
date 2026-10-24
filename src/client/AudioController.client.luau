--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local SoundService=game:GetService("SoundService")
local Players=game:GetService("Players")
local Config=require(ReplicatedStorage.Shared.Config)
local Network=require(ReplicatedStorage.Shared.Network)

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild(Network.FolderName)
local settings={Music=true,SFX=true}
local sounds={}

local function make(name,id,looped,volume)
	local s=Instance.new("Sound")
	s.Name=name
	s.SoundId=id>0 and ("rbxassetid://"..id) or ""
	s.Looped=looped
	s.Volume=volume
	s.Parent=SoundService
	sounds[name]=s
	return s
end

local ambience=make("Ambience",Config.SoundIds.Ambience,true,.3)
local wake=make("WakeSting",Config.SoundIds.WakeSting,false,.65)
local chase=make("FinalChase",Config.SoundIds.FinalChase,true,.5)
local checkpoint=make("Checkpoint",Config.SoundIds.Checkpoint,false,.55)
local win=make("Win",Config.SoundIds.Win,false,.7)

if ambience.SoundId~="" then ambience:Play() end

remotes.Profile.OnClientEvent:Connect(function(profile)
	if profile and profile.Settings then
		settings=profile.Settings
		ambience.Volume=settings.Music and .3 or 0
		chase.Volume=settings.Music and .5 or 0
	end
end)

remotes.WakePulse.OnClientEvent:Connect(function()
	if settings.SFX and wake.SoundId~="" then wake:Play() end
end)
remotes.Checkpoint.OnClientEvent:Connect(function()
	if settings.SFX and checkpoint.SoundId~="" then checkpoint:Play() end
end)
remotes.Round.OnClientEvent:Connect(function(state)
	if state.phase=="FINAL" then
		if settings.Music and chase.SoundId~="" and not chase.IsPlaying then chase:Play() end
	else
		if chase.IsPlaying then chase:Stop() end
	end
end)
