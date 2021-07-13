local DifferenceCheck = require(script.Parent.Parent.DifferenceCheck)

-- stolen from Rodux
local function createReducer(initialState, handlers)
	return function(state, action)
		if state == nil then
			state = initialState
		end

		local handler = handlers[action.type]

		if handler then
			return handler(state, action)
		end

		return state
	end
end

return createReducer({}, {
	
	change = function(state, action)
		
		local new = DifferenceCheck:applyDifferences(state, action.differences)
		
		return new
		
	end,
	
	set = function(state, action)
		return action.state
	end
})