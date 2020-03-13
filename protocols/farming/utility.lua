local utility = {}
setmetatable(utility, { __index = _G })

utility.seedTypes = {
	"minecraft:wheat_seeds",
	"minecraft:carrot",
	"minecraft:potato",
	"minecraft:melon_seeds"
}

function utility.load()
	if not fs.exists("/protocols/farming/.data") then
		return nil
	end

	local file = fs.open("/protocols/farming/.data", "r")
	local data = file.readAll()
	file.close()

	return textutils.unserialise(data)
end

function utility.save(data)
	local file = fs.open("/protocols/farming/.data", "w")
	file.write(textutils.serialise(data))
	file.close()
end

function utility.validateSeed(seedName)
	for i,v in pairs(utility.seedTypes) do
		if v == seedName then
			return true
		end
	end
	return false
end

return utility
