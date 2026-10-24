--!strict
local SettingsService={}
local services
local DEFAULT={Music=true,SFX=true,CameraShake=true,ReducedFlashes=false,PerformanceMode=false,AutoSpectate=true}

function SettingsService.Init(allServices) services=allServices end

function SettingsService.Get(player)
	local data=services.PlayerDataService.Get(player)
	if not data then return DEFAULT end
	data.Settings=data.Settings or table.clone(DEFAULT)
	return data.Settings
end

function SettingsService.Update(player,key,value)
	local settings=SettingsService.Get(player)
	if DEFAULT[key]==nil or typeof(DEFAULT[key]) ~= typeof(value) then return false end
	settings[key]=value
	return true,settings
end

return SettingsService
