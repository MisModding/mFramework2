local JSON = require('mFramework2.Modules.JSON')

local function isInvalidEvent(event)
    if (not event) or (event.type == '' or type(event.type) ~= 'string') then return true end
    if (not type(event.data) == 'table') or (event.data == {}) then return true end
    return false
end

local function SetCVar(var, val) if (var ~= '' or nil) or (val ~= nil) then System.SetCVar(var, val) end end

--
-- ────────────────────────────────────────────────── CUSTOMENTITY DEFINITION ─────
--

CustomPlayer = {
    Client = {
        ClSetCVarString = function(self, varName, valueString)
            if assert_arg(1, varName, 'string') then return false, 'invalid varName, must be a string' end
            if assert_arg(2, valueString, 'string') then return false, 'invalid valueString, must be a string' end
            SetCVar(varName, valueString)
            mFramework2.Debug(
             'CustomPlayer', string.expand('Successfully SetCVar: ${var} newvalue: ${val}', {var = varName, val = valueString})
            )
            return true, 'SetCVarString: Ok'
        end,
        ClSetCVarNumber = function(self, varName, valueNumber)
            if assert_arg(1, varName, 'string') then return false, 'invalid varName, must be a string' end
            if assert_arg(2, valueNumber, 'string') then return false, 'invalid valueNumber, must be a number' end
            SetCVar(varName, valueNumber)
            mFramework2.Debug(
             'CustomPlayer',
             string.expand('Successfully SetCVar: ${var} newvalue: ${val}', {var = varName, val = tostring(valueNumber)})
            )
            return true, 'SetCVarNumber: Ok'
        end,
        ClEventReceive = function(self, event_string, source_Id, target_Id)
            if (not source_Id == NULL_ENTITY) then
                if (not source_Id) or (not System.GetEntity(source_Id)) then return false, 'invalid source_id' end
            end
            if (not target_Id == NULL_ENTITY) then
                if (not target_Id) or (not System.GetEntity(target_Id)) then return false, 'invalid target_id' end
            end
            local event = JSON.parse(event_string)
            mFramework2.Debug(
             'CustomPlayer', string.expand('Recieved Event: ${name} data: ${data}', {name = event.type, data = event_string})
            )
            if (not event) or isInvalidEvent(event) then return false, 'invalid event' end
            return self:CustomEventHandler(event, source_Id, target_Id)
        end,
    },
    Server = {
        SvEventReceive = function(self, event_string, source_Id, target_Id)
            if (not source_Id == NULL_ENTITY) then
                if (not source_Id) or (not System.GetEntity(source_Id)) then return false, 'invalid source_id' end
            end
            if (not target_Id == NULL_ENTITY) then
                if (not target_Id) or (not System.GetEntity(target_Id)) then return false, 'invalid target_id' end
            end
            local event = JSON.parse(event_string)
            mFramework2.Debug(
             'CustomPlayer', string.expand('Recieved Event: ${name} data: ${data}', {name = event.type, data = event_string})
            )
            if (not event) or isInvalidEvent(event) then return false, 'invalid event' end
            return self:CustomEventHandler(event, source_Id, target_Id)
        end,
    },
}

function CustomPlayer:CustomEventHandler(event, source_Id, target_Id)
    -- try to find Handler
    local handler = FindInTable(g_CustomPlayerEvents, 'type', event['type'])
    -- Hand over to Registered Handler if it Exists
    if handler then
        if (type(handler['method']) == 'function') then
            mFramework2.Debug('CustomPlayer:Event', string.expand('Run Handler for Event: ${evt}', {evt = event.type}))
            return handler.method(self, event, source_Id, target_Id)
        end
    else
        mFramework2.Debug('CustomPlayer:Event', string.expand('UnKnown Event: ${evt}', {evt = event.type}))
        return
    end
end

--- SendEvent To Server ({Event}, sourceId, targetId)
---@param event table Table Defining the Event
-- Event: {
--        Type = 'STRING', -- Event Type (Event Name, this should be the Same as Your Event Handler)
--        Data = 'TABLE', -- Your Event Data this Table can be anything but can only contain STRING or NUMBER values
--    }
---@param sourceId userdata Event Source
---@param targetId userdata Event Target
-- ! IMPORTANT Source/Target EntityId Must allways Be relevant to Both the Server and Client Involved
function CustomPlayer:SendEventToServer(event, sourceId, targetId)
    if (not sourceId) or (sourceId == false) then sourceId = NULL_ENTITY end
    if (not targetId) or (targetId == false) then targetId = NULL_ENTITY end
    local event_string = JSON.stringify(event)
    return self.server:SvEventReceive(event_string, sourceId, targetId)
end

--- SendEvent To a Client ({Event}, sourceId, targetId, braadcast) broadcast true to send to all
---@param event table Table Defining the Event
--- Event: {
---    Type = 'STRING', -- Event Type (Event Name, this should be the Same as Your Event Handler)
---    Data = 'TABLE', -- Your Event Data this Table can be anything but can only contain STRING or NUMBER values
---}
---@param sourceId userdata Optional Event Source
---@param targetId userdata Optional Event Target
--- ! IMPORTANT Source/Target EntityId Must allways Be relevant to Both the Server and Client Involved
---@param broadcast boolean set true to SendToAllClients
function CustomPlayer:SendEventToClient(event, sourceId, targetId, broadcast)
    if (not sourceId) or (sourceId == false) then sourceId = NULL_ENTITY end
    if (not targetId) or (targetId == false) then targetId = NULL_ENTITY end

    local event_string = JSON.stringify(event)
    if broadcast then
        return self.allClients:ClEventReceive(event_string, sourceId, targetId)
    else
        return self.onClient:ClEventReceive(self.actor:GetChannel(), event_string, sourceId, targetId)
    end
end

--
-- ──────────────────────────────────────────────────────── EXPOSE DEFINITION ─────
--
CustomExpose = {
    ServerProperties = {},
    ClientMethods = {
        ClEventReceive = {RELIABLE_ORDERED, POST_ATTACH, STRING, ENTITYID, ENTITYID},
        ClSetCVarString = {RELIABLE_ORDERED, POST_ATTACH, STRING, STRING},
        ClSetCVarNumber = {RELIABLE_ORDERED, POST_ATTACH, STRING, INT16},
    },
    ServerMethods = {SvEventReceive = {RELIABLE_ORDERED, POST_ATTACH, STRING, ENTITYID, ENTITYID}},
}

Log(' - Loading mFramework CustomPlayer')
local _status, _result = mReExpose('Player', CustomPlayer, CustomExpose);
Log('>> Result: ' .. tostring(_status or 'Failed') .. ' ' .. tostring(_result or 'No Message'));
