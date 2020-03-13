function string.split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function string.startsWith(inputstr, sub)
	return string.sub(inputstr, 1, #sub) == sub
end

function string.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string.join(tbl, joiner)
	local joined = ""
	for i,v in pairs(tbl) do
		if i == 1 then
			joined = v
		else
			joined = joined .. " " .. v
		end
	end
	return joined
end

local ProfileManager = dofile("/helpers/profile-manager.lua")
local ProtocolExecutor = dofile("/helpers/protocol-executor.lua")
local NetworkManager = dofile("/helpers/network-manager.lua")
local MutexHelper = dofile("/helpers/mutex-helper.lua")
local TurtleUtility = dofile("/helpers/turtle-utility.lua")

-- Set up the mutex with thread consumers
local inventoryLock = MutexHelper.init()
local profileManagerMutexConsumer = inventoryLock:getConsumer("profile-manager")
local protocolExecutorMutexConsumer = inventoryLock:getConsumer("executor")

local turtleUtility = TurtleUtility.init(protocolExecutorMutexConsumer)

-- Normalize the equipped slots (i.e. modem goes on the left)
turtleUtility:normalizedEquipped()

local protocolExecutor = ProtocolExecutor.init(protocolExecutorMutexConsumer, turtleUtility)
local profileManager = ProfileManager.init(protocolExecutor, profileManagerMutexConsumer)
local networkManager = NetworkManager.init(protocolExecutor, profileManager)

function protocolExecutionLoop()
	while true do
		protocolExecutor:executionLoop()
	end
end

function networkListener()
	while true do
		networkManager:listen()
	end
end

parallel.waitForAll(protocolExecutionLoop, networkListener)
