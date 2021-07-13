--[[
	
	VERSION 1.0

	A module designed for allowing easy replication of RoduxStores between the client and server.
	This module allows:
		- Dispatching Actions to Server Rodux Store
		- Read Rodux Stores
		- See which player dispatched the Rodux Store on the server
	
	This can be combined with stuff like Roact to easily write code that lets you sync servers
	and clients states with ease.
	
	DOCUMENTATION:
	
	RoduxReplicate:register(key: string, RoduxStore: RoduxStore, options: table?) -> RoduxReplicationInfo [SERVER]
		Registers the RoduxStore and allows it to be received from other clients with the provided key.
		
	RoduxReplicate:receive(key: string) -> RoduxStore [CLIENT]
		Retrieves a RoduxStore that the server has registered.
	
	-- RoduxReplicationInfo
	
	RoduxReplicationInfo:setOptions(options: table)
		Changes the options you have given before to the new options.
		
	RoduxReplicationInfo:unregister()
		Unregisters the RoduxStore preventing clients from receiving the
		RoduxStore again.
		
		NOTE: 
			RoduxReplicate doesn't automatically call :unregister() when your RoduxStore is destroyed.
			It is recommended that you call :unregister() after your RoduxStore has been destroyed.
		
	-- Options
	
		{
			UseWhitelist: boolean = false,
				This option determines if the RoduxStore should use a Whitelist or a Blacklist
			Filter: table = {},
				A table that contains a list of players that will be filtered.
			AllowPlayerDispatchedActions: boolean = true
				Determines if players are capable of dispatching actions to the RoduxStore.
		}
	
	--
	
	WARNING:
	Rodux is expected to be located directly within ReplicatedStorage.
	If this is not the case, set the Rodux variable to locate to Rodux inside this script.
	
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Rodux)

local RoduxReplicate = {}

--[[
	
notes:
we basically keep server and client as seperate modules and wrap them
here so that intellisense will pick it up and improve the quality

]]

local RoduxReplicateApi
if RunService:IsServer() then
	RoduxReplicateApi = require(script.Server)
else
	RoduxReplicateApi = require(script.Client)
end

-- server api

function RoduxReplicate:register(key: string, RoduxStore: RoduxStore, options: table?)
	
	assert(RunService:IsServer(), "This method can only be run on the server!")
	
	return RoduxReplicateApi:registerRoduxStore(key, RoduxStore, options)
	
end


-- client api

function RoduxReplicate:receive(key: string)
	
	assert(RunService:IsClient(), "This method can only be run on the client!")
	RoduxReplicateApi:init(Rodux)
	return RoduxReplicateApi:receive(key)
	
end

return RoduxReplicate