--[[
	Written by Megustral
	
	Returns differences between 2 tables deep.
]]

local differenceChecker = {}
local None = string.pack("f", "-412501") -- special packed string to ensure when a variable is set to nil it gets replicated smoothly

local function deepCopy(table)
	
	local copy = {}
	
	for key, value in pairs(table) do
		copy[key] = value
	end
	
	return copy
	
end

function differenceChecker:searchDifferences(old, new)
	
	local differences = {}
	
	for key, valueB in pairs(new) do
		--print(key, valueB)
		local valueA = old[key]
		
		if type(valueB) == "table" and type(valueA) == "table" then
			
			differences[key] = differenceChecker:searchDifferences(valueA, valueB)
			
		-- check if the value is the same. if it is not, record it as old difference
		elseif valueA ~= valueB then
			
			differences[key] = valueB
		end
	end
	
	-- look for changes in which stuff is set to nil.
	-- if they are, set them to a special value.
	for key, valueA in pairs(old) do
		local valueB = new[key]
		
		if valueB == nil then
			differences[key] = None
		end
	end
	
	return differences
	
end

function differenceChecker:applyDifferences(old, differences)
	
	local new = deepCopy(old)
	
	-- go through all differences
	for key, newValue in pairs(differences) do
		--print(key, newValue, new[key])
		-- if its a table, proceed to call this function recursively to apply
		-- all the differences
		if type(newValue) == "table" and type(new[key]) == "table" then
			new[key] = differenceChecker:applyDifferences(new[key], newValue)
		else
			
			-- set it to nil since it matches
			if newValue == None then
				newValue = nil
			end
			
			new[key] = newValue
		end
		
	end
	
	return new
	
end

return differenceChecker