--[[	
	Provides the server interface for RoduxReplicate and handles
	creating the remotes required for setting up RoduxReplicate.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedStore = require(script.ReplicatedStore)

local RoduxReplicateServer = {}

--[[
	registers a new RoduxStore that the client is capable of retrieving.
	it will register with the provided key and will be changed by the
	defined options.
	
	Options: {
		UseWhitelist: boolean = false,
		Filter: table = {},
		AllowPlayerDispatchedActions: boolean = true
	}
	
]]
function RoduxReplicateServer:registerRoduxStore(key, roduxStore: RoduxStore, options)
	
	return ReplicatedStore.new(key, options, roduxStore)
	
end

return RoduxReplicateServer
