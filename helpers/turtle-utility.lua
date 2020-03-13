local turtleUtility = {
	inventoryLock = nil
}
turtleUtility.__index = turtleUtility

function turtleUtility.init(inventoryLock)
	local self = setmetatable(turtleUtility, {})
	self.inventoryLock = inventoryLock
	return self
end

function turtleUtility:getDirection()
	local anchorX, anchorY, anchorZ = gps.locate()

	if not turtle.forward() then
		return false, "Out of fuel"
	end

	local curX, curY, curZ = gps.locate()

	if not turtle.back() then
		return false, "Out of fuel"
	end

	if curX - anchorX > 0 then
		return "e"
	elseif curX - anchorX < 0 then
		return "w"
	elseif curZ - anchorZ > 0 then
		return "s"
	elseif curZ - anchorZ < 0 then
		return "n"
	end
end

function turtleUtility:faceNorth()
	local currentDirection, err = turtleUtility:getDirection()
	if not currentDirection then
		return false, err
	end

	if currentDirection == "s" then
		turtle.turnRight()
		turtle.turnRight()
	elseif currentDirection == "w" then
		turtle.turnRight()
	elseif currentDirection == "e" then
		turtle.turnLeft()
	end

	return true
end

function turtleUtility:placeDown(item)
	self.inventoryLock:wait()
	self.inventoryLock:lock()

	turtleUtility:selectItem(item)
	turtle.placeDown()

	self.inventoryLock:unlock()
end

-- Don't worry about the mutex here because the calling function will be responsible for calling
-- it
function turtleUtility:selectItem(name)
	-- Do a quick check first to see if we are already selecting the right slot
	local curDetails = turtle.getItemDetail()
	if (name == nil and turtle.getItemCount() == 0) or (details ~= nil and details.name == name) then
		return true
	end
	for i = 1, 16 do
		local details = turtle.getItemDetail(i)
		if (name == nil and turtle.getItemCount(i) == 0) or (details ~= nil and details.name == name) then
			turtle.select(i)
			return true
		end
	end
	return false
end

function turtleUtility:totalCountOf(item)
	-- Lock the mutex
	local total = 0
	for i = 1, 16 do
		local details = turtle.getItemDetail(i)
		if details and details.name == item then
			total = total + details.count
		end
	end
	return total
end

function turtleUtility:normalizedEquipped()
	-- Wait until inventory is available
	self.inventoryLock:wait()

	-- Lock the mutex
	self.inventoryLock:lock()

	-- Clear the two equipped slots
	turtleUtility:selectItem()
	turtle.equipRight()
	turtleUtility:selectItem()
	turtle.equipLeft()

	-- Equip the modem in the left side if it exists
	if turtleUtility:selectItem("computercraft:CC-Peripheral") then
		turtle.equipLeft()
	end

	-- Unlock the mutex
	self.inventoryLock:unlock()
end

function turtleUtility:clearEquipped()
	-- Wait until inventory is available
	self.inventoryLock:wait()

	-- Lock the mutex
	self.inventoryLock:lock()

	-- Modems will always be on the left slot so we don't need to clear it
	turtleUtility:selectItem()
	turtle.equipRight()

	-- Unlock the mutex
	self.inventoryLock:unlock()
end

function turtleUtility:forwardOrBreak()
	if turtle.detect() then
		turtle.dig()
	end
	return turtle.forward()
end

function turtleUtility:upOrBreak()
	if turtle.detectUp() then
		turtle.digUp()
	end
	return turtle.up()
end

function turtleUtility:downOrBreak()
	if turtle.detectDown() then
		turtle.digDown()
	end
	return turtle.down()
end

function turtleUtility:tableContains(tbl, item)
	for i,v in pairs(tbl) do
		if v == item then
			return true
		end
	end
	return false
end

function turtleUtility:emptyInventory(keptItems, invertKeptItems)
	self.inventoryLock:wait()
	self.inventoryLock:lock()

	for i = 1, 16 do
		local details = turtle.getItemDetail(i)
		local itemIsListed = details ~= nil and turtleUtility:tableContains(keptItems or {}, details.name)

		if invertKeptItems then
			itemIsListed = not itemIsListed
		end

		if not itemIsListed then
			turtle.select(i)
			turtle.dropDown()
		end
	end

	self.inventoryLock:unlock()
end

function turtleUtility:gotoPoint(x, y, z)
	-- Start by facing north and clearing equipped items for normalization
	turtleUtility:faceNorth()
	turtleUtility:clearEquipped()
	local direction = "n"

	-- Get the current position
	local curX, curY, curZ = gps.locate()
	if curX == x and curY == y and curZ == z then
		return
	end

	-- Go up really high to avoid obstacles easily
	for i=1, 8 do
		turtle.up()
	end

	curX, curY, curZ = gps.locate()

	-- Get the difference on the z axis, if it is positive, we want to face south
	-- otherwise, we are fine facing north
	local zDiff = z - curZ
	if zDiff > 0 then
		direction = "s"
		turtle.turnRight()
		turtle.turnRight()
	end

	-- Keep going north or south until we are at the correct z position
	while curZ ~= z do
		turtleUtility:forwardOrBreak()
		curX, curY, curZ = gps.locate()
	end

	-- Normalize by facing north
	if direction == "s" then
		turtle.turnRight()
		turtle.turnRight()
	end

	-- Get the difference on the x axis, if it is positive, we want to face east
	-- if it is negative, we want to face west
	local xDiff = x - curX
	if xDiff > 0 then
		direction = "e"
		turtle.turnRight()
	else
		direction = "w"
		turtle.turnLeft()
	end

	-- Keep going east or west until we are at the correct x position
	while curX ~= x do
		turtleUtility:forwardOrBreak()
		curX, curY, curZ = gps.locate()
	end

	-- Get the difference on the y axis, if it is positive, we want to go up,
	-- if it is negative, we want to go down
	local yDiff = y - curY
	local upOrDown = nil
	if yDiff > 0 then
		upOrDown = function()
			self:upOrBreak()
		end
	else
		upOrDown = function()
			self:downOrBreak()
		end
	end

	-- Keep going up or down until we are at the correct y position
	while curY ~= y do
		upOrDown()
		curX, curY, curZ = gps.locate()
	end

	-- Face north again
	if direction == "e" then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
end

return turtleUtility
