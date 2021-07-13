--[[
	Written by Megustral
	
	Client-side module for handling RoduxReplicate and incoming RoduxReplicate connections.
]]

local Rodux: Rodux
local Reducer = require(script.Reducer)

local RoduxReplicateClient = {}
local RoduxStoreWrapper = {}
local RoduxConnected = {}

-- returns a wrapped RoduxStore that provides access
function RoduxReplicateClient:receive(key: string)
	
	-- check if the Store is registered
	local Remotes = script.Parent.Remotes:FindFirstChild(key)
	assert(Remotes, "There is no registered store with the name "..key)
	
	local RoduxStore = Rodux.Store.new(Reducer)
	local Wrapped = setmetatable({
		Key = key,
		RoduxStore = RoduxStore
	}, {
		__index = RoduxStore
	})

	-- dispatch a action to sync the state with the server and client
	RoduxStore:dispatch({
		type = "set",
		state = Remotes.connect:InvokeServer()
	})
	
	-- setup the events required
	Wrapped._changed = Remotes.changed.OnClientEvent:Connect(function(differences)
		--print("received changes", differences)
		RoduxStore:dispatch({
			type = "change",
			differences = differences
		})
	end)
	Wrapped._dispatch = Remotes.dispatch
	Wrapped.dispatch = RoduxStoreWrapper.dispatch
	Wrapped.destruct = RoduxStoreWrapper.destruct
	
	Wrapped._ancestrychanged = Remotes.AncestryChanged:Connect(function(_, newAncestor)
		if newAncestor == nil then
			Wrapped:destruct()
		end
	end)
	
	-- insert it into the list of connections
	table.insert(RoduxConnected, key)
	
	return Wrapped
	
end

function RoduxReplicateClient:init(RoduxModule)
	
	Rodux = RoduxModule
end

function RoduxStoreWrapper:destruct()
	
	table.remove(RoduxConnected, table.find(RoduxConnected, self.Key))
	
	if not table.find(RoduxConnected, self.Key) then
		local Remotes = script.Parent.Remotes:FindFirstChild(self.Key)
		
		if Remotes then
			Remotes.disconnect:FireServer()
		end
	end
	
	self._changed:Disconnect()
	self._ancestrychanged:Disconnect()
	
	self.RoduxStore:destruct()
end

function RoduxStoreWrapper:dispatch(action)
	self._dispatch:InvokeServer(action)
end

return RoduxReplicateClient