local protocolExecutor = {
	availableCommands = {},
	commandFunction = nil,
	currentCoroutine = nil,
	shouldLoop = false,
	protocol = "",
	cancelled = true,
	turtleUtility = nil,
	inventoryLock = nil,
	currentCommand = nil,
	networkManager = nil,
}

function protocolExecutor.init(inventoryLock, turtleUtility)
	local self = setmetatable(protocolExecutor, {})
	self.inventoryLock = inventoryLock
	self.turtleUtility = turtleUtility
	return self
end

function protocolExecutor:setNetworkManager(networkManager)
	self.networkManager = networkManager
end

-- Loads all available commands
function protocolExecutor:toggleCancelled()
	self.cancelled = not self.cancelled
end

function protocolExecutor:getAvailableCommands()
	return self.availableCommands
end

function protocolExecutor:analyizeCommand(command)
	local path = "/protocols/" .. self.protocol .. "/" .. command .. ".protocol"

	local file = io.open(path, "r")

	if file == nil then
		return {
			params = {},
			defaultLoop = false,
		}
	end

	local command = {
		params = {},
		defaultLoop = false,
	}

	for line in file:lines() do
		if string.startsWith(line, "--PARAM") then
			local parts = string.split(line, ":")
			command.params[parts[2]] = parts[3]
		elseif string.startsWith(line, "--LOOP_DEFAULT") then
			command.defaultLoop = true
		end
	end

	return command
end

function protocolExecutor:loadProtocol(protocol)
	if not fs.exists("/protocols/" .. protocol) then
		return false, "No protocol folder"
	end

	self.protocol = protocol

	local files = fs.list("/protocols/" .. protocol)

	for i,v in pairs(files) do
		if string.sub(v, -8) == "protocol" then
			local commandName = string.sub(v, 1, -10)
			self.availableCommands[commandName] = self:analyizeCommand(commandName)
		end
	end

	return true
end

function protocolExecutor:setCommand(command, loop, params)
	if self.availableCommands[command] == nil then
		return false, "No command by that name"
	end

	-- Configure looping behavior for the command
	if self.availableCommands[command].defaultLoop or loop then
		self.shouldLoop = true
	else
		self.shouldLoop = false
	end

	self.cancelled = false
	self.currentCommand = command

	local f, err = loadfile("/protocols/" .. self.protocol .. "/" .. self.currentCommand .. ".protocol")

	if err then
		self.networkManager:sendError(err)
		return
	end

	local sendMessage = function(message)
		self.networkManager:sendMessage(message)
	end

	-- Create the command function
	self.commandFunction = function()
		self.networkManager:updateServer()
		local success, errMessage = f(params, self.turtleUtility, sendMessage)

		if success == false then
			self.networkManager:sendError(errMessage)
		end
	end
end

function protocolExecutor:cancelFunction()
	while true do
		if self.cancelled then
			return
		end
		os.sleep(0.2)
	end
end

function protocolExecutor:executionLoop()
	if self.commandFunction == nil then
		os.sleep(0.2)
		return
	end

	parallel.waitForAny(self.commandFunction, function()
		self:cancelFunction()
	end)
	
	if not self.shouldLoop or self.cancelled then
		self.commandFunction = nil
	end
	self.cancelled = false
	self.currentCommand = nil
	self.networkManager:updateServer()
	os.sleep(0.2)
end

return protocolExecutor
