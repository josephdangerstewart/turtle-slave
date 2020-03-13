local networkManager = {
	protocolExecutor = {},
	profileManager = {}
}
networkManager.__index = networkManager

function networkManager.init(protocolExecutor, profileManager)
	for i,v in pairs(peripheral.getNames()) do
		if peripheral.getType(v) == "modem" then
			rednet.open(v)
		end
	end

	local self = setmetatable(networkManager, {})
	self.protocolExecutor = protocolExecutor
	self.protocolExecutor:setNetworkManager(self)
	self.profileManager = profileManager

	if self.profileManager.firstTimeSetUpFlag then
		self:registerWithServer()
	end

	return self
end

function networkManager:registerWithServer()
	local message = {}
	message.protocol = "general"
	message.command = "register"
	message.turtle = self.profileManager:getProfile()

	self:send(message)
end

function networkManager:listen()
	e, a, b, c, d, e = os.pullEvent()

	if e == "rednet_message" and a == self.profileManager.serverId then
		self:handleRednetMessage(a, textutils.unserialise(b), c)
	end
end

function networkManager:handleRednetMessage(id, message, d)
	local command = message.protocol .. "." .. message.command
	local response = {}

	if command == "general.ping" then
		response.protocol = "general"
		response.command = "update"
		response.turtle = self.profileManager:getProfile()
		self:send(response)
	elseif command == "turtle.toggle_pause" then
		self.protocolExecutor:toggleCancelled()
		self:updateServer()
	elseif message.protocol == "protocol" then
		self.protocolExecutor:setCommand(message.command, false, message.params)
	end
end

function networkManager:send(message)
	message.turtle = self.profileManager:getProfile()
	rednet.send(self.profileManager.serverId, textutils.serialise(message))
end

function networkManager:sendMessage(message)
	local messageDto = {
		protocol = "general",
		command = "message",
		message = message,
	}
	self:send(messageDto)
end

function networkManager:sendError(errorMessage)
	local messageDto = {
		protocol = "general",
		command = "error",
		message = errorMessage,
	}
	self:send(messageDto)
end

function networkManager:updateServer()
	local message = {
		protocol = "general",
		command = "update",
	}
	self:send(message)
end

return networkManager
