-- This class exists so that programs running in different threads
-- can lock access to the turtles inventory to prevent a scenario
-- where a command programs selects a block (dirt for example), then
-- the profile manager takes inventory thus selecting a different block,
-- then the command program places a block thinking its dirt but it's
-- actually not


-- Mutex consumers avoid the problem of a thread locking the mutex, then calling another
-- function that waits for the mutex, if a consumer waits for the mutex that was locked by
-- that consumer, then it will pass
local mutexConsumer = {
	name = "",
	mutex = nil
}
mutexConsumer.__index = mutexConsumer

function mutexConsumer:wait()
	self.mutex:wait(self.name)
end

function mutexConsumer:isLocked()
	return self.mutex:isLocked(self.name)
end

function mutexConsumer:lock()
	self.mutex:lock(self.name)
end

function mutexConsumer:unlock()
	self.mutex:unlock(self.name)
end

function mutexConsumer.init(name, mutex)
	local self = setmetatable({}, mutexConsumer)
	self.__index = self
	self.name = name
	self.mutex = mutex
	return self
end

-- The actual mutex class manages the lock state
local mutex = {
	locked = false,
	consumer = "",
}
mutex.__index = mutex

function mutex.init()
	local self = setmetatable(mutex, {})
	return self
end

function mutex:getConsumer(consumerName)
	return mutexConsumer.init(consumerName, self)
end

function mutex:wait(consumerName)
	while self:isLocked(consumerName) do
		os.sleep(0.1)
	end
end

function mutex:isLocked(consumerName)
	return self.locked and consumerName ~= self.consumer
end

function mutex:lock(consumerName)
	self.locked = true
	self.consumer = consumerName
end

function mutex:unlock()
	self.locked = false
	self.consumer = ""
end

return mutex
