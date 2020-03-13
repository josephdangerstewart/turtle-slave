local profileManager = {
	me = {
		name = "",
		id = 0,
		fuel = 0,
		protocol = "farming",
		fuelLimit = 0,
		online = true,
		inventory = {},
		peripherals = {},
		cancelled = false,
		protocolActions = {},
	},
	serverId = 0,
	protocolExecutor = {},
	firstTimeSetupFlag = false,
	inventoryLock = nil
}
profileManager.__index = profileManager

function profileManager.init(protocolExecutor, inventoryLock)
	local self = setmetatable(profileManager, {})
	self.protocolExecutor = protocolExecutor
	self.inventoryLock = inventoryLock

	-- If there is no profile then let's set one up
	if not fs.exists("/profile.data") then
		self:firstTimeSetUp()
		self.firstTimeSetUpFlag = true
	end

	-- Load the profile file
	local file = fs.open("/profile.data", "r")
	local data = textutils.unserialise(file.readAll())
	file.close()

	-- Set name, serverId, and protocol from file
	self.me.name = data.name
	self.serverId = data.serverId
	self.me.protocol = data.protocol

	-- Set fuel and fuel limits
	self.me.fuel = turtle.getFuelLevel()
	self.me.fuelLimit = turtle.getFuelLimit()

	-- Set ID
	self.me.id = os.getComputerID()

	-- Set inventory
	self:getInventoryData()

	-- Set peripherals
	self:getPeripheralData()

	-- Set cancelled
	self.me.cancelled = protocolExecutor.cancelled

	-- Set current command
	self.me.currentCommand = protocolExecutor.currentCommand

	-- Load the protocol and set protocol actions
	protocolExecutor:loadProtocol(self.me.protocol)
	self.me.protocolActions = protocolExecutor:getAvailableCommands()

	return self
end

function profileManager:getInventoryData()
	self.me.inventory = {}
	for row = 1, 4 do
		self.me.inventory[row] = {}
		for col = 1, 4 do
			self.me.inventory[row][col] = turtle.getItemDetail((row - 1)*4 + col)
		end
	end
end

function profileManager:getPeripheralData()
	self.me.peripherals = {}
	for i,v in pairs(peripheral.getNames()) do
		table.insert(self.me.peripherals, peripheral.getType(v))
	end
end

function profileManager:getProfile()
	self:getInventoryData()
	self:getPeripheralData()
	self.me.fuel = turtle.getFuelLevel()
	self.me.fuelLimit = turtle.getFuelLimit()
	self.me.cancelled = self.protocolExecutor.cancelled
	self.me.currentCommand = self.protocolExecutor.currentCommand

	return self.me
end

function profileManager:firstTimeSetUp()
	local flag = "n"
	local name, serverId, protocol
	
	while flag ~= "y" and flag ~= "Y" do
		term.clear()
		term.setCursorPos(1,1)
		print("Turtle Slave by PossieTV")
		print("First time set up")
		print()
		term.write("Turtle Name: ")
		name = read()

		term.write("Server id: ")
		serverId = tonumber(read())

		print()
		local validProtocols = fs.list("/protocols")
		term.write("Protocols: ")
		for i,v in pairs(validProtocols) do
			term.write(v)
			if i ~= #validProtocols then
				term.write(", ")
			end
		end

		print()

		term.write("Protocol: ")
		protocol = read()

		print()

		if not fs.exists("/protocols/" .. protocol .. "/") then
			term.write(protocol .. " is not a valid protocol.")
			read()
		else
			term.write("Is this information correct (y/n)? ")
			flag = read()
		end
	end

	local file = fs.open("/profile.data", "w")
	file.write(textutils.serialise({
		name = name,
		serverId = serverId,
		protocol = protocol
	}))
	file.close()
end

return profileManager
