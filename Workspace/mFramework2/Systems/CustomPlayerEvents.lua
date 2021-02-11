--- Contains all Registered CustomPlayer Events
g_CustomPlayerEvents = {}

--- Create a new PlayerEvent
---@param	eventType string
---@param	method	fun(player:table,event:table,sourceId:EntityId,targetId:EntityId)
---@return	boolean,string
function mFramework2.CreatePlayerEvent(eventType, method)
    local event = FindInTable(g_CustomPlayerEvents, 'type', eventType)
    if (not event) then
        if (type(method) == 'function') then
            InsertIntoTable(g_CustomPlayerEvents, {type = eventType, method = method})
            mFramework2.Debug('CustomPlayer', string.expand('registered Event: ${name}', {name = eventType}))
            return true, 'event created'
        end
        mFramework2.Debug('CustomPlayer', string.expand('failed to register Event: ${name}', {name = eventType}))
        return false, 'event exists'
    end
end

local Sandbox = require('mFramework2.Classes.Sandbox')
local RMI_Sandbox = Sandbox() ---@type Sandbox
--- create a player event
local evt_created, evt_msg = mFramework2.CreatePlayerEvent('runScript', function(player, event, sourceId, targetId)
    local scriptToRun = event.data['script']
    mFramework2.Debug('event:runScript', 'Recieved Event: ' .. (scriptToRun or 'no data'))
    if scriptToRun then
        --- Disallow debug library in RMI calls
        RMI_Sandbox:Mutate{debug = NULL}

        RMI_Sandbox:runScript(scriptToRun)
    end
end)
--- log event creation
if (not evt_created) then
    mFramework2.Debug('CustomPlayer', string.expand('register Event failed: runScript > ${res}', {res = evt_msg}))
else
    mFramework2.Debug('CustomPlayer', string.expand('register Event Ok: runScript > ${res}', {res = evt_msg}))
end
