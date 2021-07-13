local DifferenceCheck = require(script.Parent.Parent.DifferenceCheck)

local ReplicateStore = {}
local ReplicatedRoduxStores = {}
local allowedOptions = {
	"UseWhitelist",
	"Filter",
	"AllowPlayerDispatchedActions"
}

ReplicateStore.__index = ReplicateStore

-- creates a copy of the table to ensure that DifferenceCheck works properly
local function deepCopy(table)
	
	local clone = {}
	
	for key, value in pairs(table) do
		
		if type(value) == "table" then
			clone[key] = deepCopy(value)
		else
			clone[key] = value
		end
		
	end
	
	return clone
	
end

-- creates a new ReplicatedStore object that lets you control the behaviour
function ReplicateStore.new(key, options, store)
	assert(not ReplicatedRoduxStores[key], "Attempted to assign a store to a already occupied key.")
	
	local self = setmetatable({
		
		Key = key,
		Store = store,
		UseWhitelist = false,
		Filter = {},
		AllowPlayerDispatchedActions = true,
		
		_oldState = deepCopy(store:getState()),
		_connected = {}
		
	}, ReplicateStore)
	
	ReplicatedRoduxStores[key] = self
	
	
	-- create the remotes required for replication
	local Remotes = Instance.new("Folder")
	local Changed = Instance.new("RemoteEvent")
	local Connect = Instance.new("RemoteFunction")
	local Dispatch = Instance.new("RemoteFunction")
	local Disconnect = Instance.new("RemoteEvent")
	
	Remotes.Name = key
	Disconnect.Name = "disconnect"
	Dispatch.Name = "dispatch"
	Changed.Name = "changed"
	Connect.Name = "connect"
	
	Disconnect.Parent = Remotes
	Dispatch.Parent = Remotes
	Changed.Parent = Remotes
	Connect.Parent = Remotes
	
	-- Allows the player to connect to the RoduxStore
	Connect.OnServerInvoke = function(player)
		
		-- perform checks to ensure if the player has access to this store
		local playerIsOnFilter = table.find(self.Filter, player)
		assert(
			self.UseWhitelist and playerIsOnFilter
			or
			not self.UseWhitelist and not playerIsOnFilter,
			"Player lacks access to this RoduxStore! Did you make sure to whitelist/unblacklist the player?"
		)
		
		-- perform another check to ensure that the player isnt already connected
		if not table.find(self._connected, player) then
			-- add the player to the list of connected players so we can see who we need to fire too later.
			table.insert(self._connected, player)
		end
		
		return store:getState()
		
	end
	
	-- Allows the player to dispatch a action to the RoduxStore
	Dispatch.OnServerInvoke = function(player, action)
		
		assert(self.AllowPlayerDispatchedActions == true, "Players are not allowed to dispatch actions")
		
		action.player = player
		store:dispatch(action)
		
	end
	
	-- disconnects the player from the store
	Disconnect.OnServerEvent:Connect(function(player)
		
		table.remove(self._connected, table.find(self._connected, player))
		
	end)
	
	-- create a changed connection for networking behaviour
	self._changed = store.changed:connect(function(newState)
		--print("received")
		-- get the differences between the newState and oldState deep.
		local Differences = DifferenceCheck:searchDifferences(self._oldState, newState)
		--print("looking for changes")
		-- update the oldState to enable better difference check
		self._oldState = deepCopy(newState)
		--print("overwriting old changes")
		-- figure out which players to replicate it to
		--print("sending changes", Differences)
		for index, playerConnected in ipairs(self._connected) do
			--print("sent to", playerConnected)
			Changed:FireClient(playerConnected, Differences)
		end
		
	end)
	
	Remotes.Parent = script.Parent.Parent.Remotes
	self:setOptions(options)
	return self
end

function ReplicateStore:setOptions(options: table)
	
	options = options or {}
	
	-- go through the list of allowed options and assign them
	for key, value in pairs(options) do
		if table.find(allowedOptions, key) then
			self[key] = value
		end
	end
	
end

-- unregisters the RoduxStore
function ReplicateStore:unregister()
	
	ReplicatedRoduxStores[self.key] = nil
	
	self._changed:disconnect()
	self._connected = nil
	self._oldState = nil
	script.Parent.Parent.remotes:WaitForChild(self.key):Destroy()
	
end

return ReplicateStore