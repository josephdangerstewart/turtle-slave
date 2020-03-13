local context = {}
setmetatable(context, { __index = _G })

function context.goup()
	turtle.up()
end

function context.godown()
	turtle.down()
end

context.numberOfDances = 0
context.x = 0

return context
