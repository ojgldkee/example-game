--!strict
local Util = {}

function Util.clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

function Util.retry<T>(attempts: number, baseDelay: number, callback: () -> T): (boolean, T?)
	local lastError: any = nil
	for attempt = 1, attempts do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			task.wait(baseDelay * (2 ^ (attempt - 1)) + math.random() * 0.25)
		end
	end
	warn("Retry exhausted:", lastError)
	return false, nil
end

function Util.safeDisconnect(connection: RBXScriptConnection?)
	if connection then
		connection:Disconnect()
	end
end

return Util
