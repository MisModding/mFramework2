local JSON = require( 'mFramework2.Modules.JSON' )

local function isInvalidEvent( event )
    if (not event) or (event.type == '' or type( event.type ) ~= 'string') then return true end
    if (not type( event.data ) == 'table') or (event.data == {}) then return true end
    return false
end

local function SetCVar( var, val )
    if (var ~= '' or nil) or (val ~= nil) then System.SetCVar( var, val ) end
end

--
-- ────────────────────────────────────────────────── CUSTOMENTITY DEFINITION ─────
--

---@class mFramework.CustomPlayer : CE3.player
---@field server table
---@field allClients table
---@field onClient table
CustomPlayer = {
    Client = {
        ClSetCVarString = function( self, varName, valueString )
            if assert_arg( 1, varName, 'string' ) then
                return false, 'invalid varName, must be a string'
            end
            if assert_arg( 2, valueString, 'string' ) then
                return false, 'invalid valueString, must be a string'
            end
            SetCVar( varName, valueString )
            mFramework2.Debug( 'CustomPlayer', string.expand(
              'Successfully SetCVar: ${var} newvalue: ${val}', {var = varName, val = valueString} ) )
            return true, 'SetCVarString: Ok'
        end,
        ClSetCVarNumber = function( self, varName, valueNumber )
            if assert_arg( 1, varName, 'string' ) then
                return false, 'invalid varName, must be a string'
            end
            if assert_arg( 2, valueNumber, 'string' ) then
                return false, 'invalid valueNumber, must be a number'
            end
            SetCVar( varName, valueNumber )
            mFramework2.Debug( 'CustomPlayer',
              string.expand( 'Successfully SetCVar: ${var} newvalue: ${val}',
                {var = varName, val = tostring( valueNumber )} ) )
            return true, 'SetCVarNumber: Ok'
        end,
        ClEventReceive = function( self, event_string, source_Id, target_Id )
            if (not source_Id == NULL_ENTITY) then
                if (not source_Id) or (not System.GetEntity( source_Id )) then
                    return false, 'invalid source_id'
                end
            end
            if (not target_Id == NULL_ENTITY) then
                if (not target_Id) or (not System.GetEntity( target_Id )) then
                    return false, 'invalid target_id'
                end
            end
            local event = JSON.parse( event_string )
            mFramework2.Debug( 'CustomPlayer', string.expand(
              'Recieved Event: ${name} data: ${data}', {name = event.type, data = event_string} ) )
            if (not event) or isInvalidEvent( event ) then return false, 'invalid event' end
            return self:CustomEventHandler( event, source_Id, target_Id )
        end,
    },
    Server = {
        SvEventReceive = function( self, event_string, source_Id, target_Id )
            if (not source_Id == NULL_ENTITY) then
                if (not source_Id) or (not System.GetEntity( source_Id )) then
                    return false, 'invalid source_id'
                end
            end
            if (not target_Id == NULL_ENTITY) then
                if (not target_Id) or (not System.GetEntity( target_Id )) then
                    return false, 'invalid target_id'
                end
            end
            local event = JSON.parse( event_string )
            mFramework2.Debug( 'CustomPlayer', string.expand(
              'Recieved Event: ${name} data: ${data}', {name = event.type, data = event_string} ) )
            if (not event) or isInvalidEvent( event ) then return false, 'invalid event' end
            return self:CustomEventHandler( event, source_Id, target_Id )
        end,
    },
}

---Internal - used to send Huge RMICalls as Multipart RMI Events
---@param To            string                  `server` OR `client`
---@param event         table<number,string>    `event json in managable chunks (between 400-900 characters)`
---@param sourceId      entityId                `(optional)source entity triggering this event`
---@param targetId      entityId                `(optional)entity this event targets`
---@param isBroadcast   boolean                 `only if To=client - broadcast to all players?`
function CustomPlayer:SendMultipartEvent( To, event, sourceId, targetId, isBroadcast )
    if assert_arg( 1, To, 'string' ) then
        return false, 'error, invalid param: To - must be \'client\' OR \'server\''
    elseif assert_arg( 2, event, 'table' ) then
        return false, 'error, invalid param: event - must be table of strings'
    end

    local chunks = event:size()
    for idx, chunk in ipairs( event ) do
        if To == 'server' then
            self:SendEventToServer( {
                Type = 'xMultipart',
                Data = {on = 'server', chunk = idx, chunks = chunks, data = chunk},
            }, sourceId, targetId )
        else
            self:SendEventToClient( {
                Type = 'xMultipart',
                Data = {on = 'client', chunk = idx, chunks = chunks, data = chunk},
            }, sourceId, targetId, isBroadcast )
        end
    end
end

g_MultipartRMI_Cache = {send = {}, recieve = {}}

local multipartParser = coroutine.wrap( function( steamId, transaction, data )
    local cache = g_MultipartRMI_Cache[steamId]
    --- create initial data cache
    if not cache[transaction.id] then cache[transaction.id] = '' end
    local compleated = false
    while (not compleated) do
        cache[transaction.id] = cache[transaction.id] .. data
        if (transaction.chunk >= transaction.chunks) then
            compleated = true
        else
            steamId, transaction, data = coroutine.yield( false )
        end
    end
    return cache[transaction.id]
end )

---[internal] recieve a MultipartRMI
---@param player player
---@param transaction table<string,number> `id:number, chunks:number, chunk:number`
---@param data string
local function RecieveMultipart( player, transaction, data, cb )
    local steamId = player.player:GetSteam64Id()
    --- ensure we have a cache for this player
    if (not g_MultipartRMI_Cache[steamId]) then g_MultipartRMI_Cache[steamId] = {} end
    local result = multipartParser( steamId, transaction, data )
    if result then cb( result ) end
end

g_CustomPlayerEvents = {}

function CustomPlayer:CustomEventHandler( event, source_Id, target_Id )
    -- process multipart events
    if event.type == 'xMultipart' then
        mFramework2.Debug( 'CustomPlayer:MultipartEvent',
          string.expand( 'Processing Data: ${chunk}/${chunks}',
            {chunk = event.data.chunk, chunks = event.data.chunks} ) )
        local handleEvent = function( data )
            if event.data['on'] == 'server' then
                self.Client:ClEventReceive( data, source_Id, target_Id )
            else
                self.Server:SvEventReceive( data, source_Id, target_Id )
            end
        end
        return RecieveMultipart( self, {
            id = 1,
            chunk = event.data['chunk'],
            chunks = event.data['chunks'],
        }, event.data['data'], handleEvent )
    end
    -- try to find Handler
    local handler = FindInTable( g_CustomPlayerEvents, 'type', event['type'] )
    -- Hand over to Registered Handler if it Exists
    if handler then
        if (type( handler['method'] ) == 'function') then
            mFramework2.Debug( 'CustomPlayer:Event',
              string.expand( 'Run Handler for Event: ${evt}', {evt = event.type} ) )
            return handler.method( self, event, source_Id, target_Id )
        end
    else
        mFramework2.Debug( 'CustomPlayer:Event',
          string.expand( 'UnKnown Event: ${evt}', {evt = event.type} ) )
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
function CustomPlayer:SendEventToServer( event, sourceId, targetId )
    if (not sourceId) or (sourceId == false) then sourceId = NULL_ENTITY end
    if (not targetId) or (targetId == false) then targetId = NULL_ENTITY end
    local do_multipart = false
    local event_string = JSON.stringify( event )
    --- max size STRING type per RMI call
    if (string.len( event_string ) >= 999) then
        do_multipart = true
        event_string = BreakUpHugeString( event_string, 400, 900 )
    end

    if do_multipart then
        self:SendMultipartEvent( 'server', event_string, sourceId, targetId )
    else
        return self.server:SvEventReceive( event_string, sourceId, targetId )
    end
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
function CustomPlayer:SendEventToClient( event, sourceId, targetId, broadcast )
    if (not sourceId) or (sourceId == false) then sourceId = NULL_ENTITY end
    if (not targetId) or (targetId == false) then targetId = NULL_ENTITY end

    local event_string = JSON.stringify( event )
    --- max size STRING type per RMI call
    if (string.len( event_string ) >= 1000) then
        do_multipart = true
        event_string = BreakUpHugeString( event_string, 400, 900 )
    end

    if do_multipart then
        self:SendMultipartEvent( 'client', event_string, sourceId, targetId, broadcast )
    else
        if broadcast then
            return self.allClients:ClEventReceive( event_string, sourceId, targetId )
        else
            return self.onClient:ClEventReceive( self.actor:GetChannel(), event_string, sourceId,
                     targetId )
        end
    end
end

Script.LoadScriptFolder( 'Scripts/mFramework2/CustomPlayerEvents' )
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

Log( ' - Loading mFramework CustomPlayer' )
local _status, _result = mReExpose( 'Player', CustomPlayer, CustomExpose );
Log( '>> Result: ' .. tostring( _status or 'Failed' ) .. ' ' .. tostring( _result or 'No Message' ) );

---* Send An event to Server or Client/allClients
---@param To string required  - EventReciever can be a specific playerId or the string `Server` or `allClients`
---@param Event table required  - EventTable
---@param source_Id userdata optional  - source entityId
---@param target_Id userdata optional  - target entityId
function mSendEvent( To, Event, source_Id, target_Id )
    -- validate
    -- TODO: Add Error Messages
    if (type( Event ) ~= 'table') or Event == {} then return end
    local thisPlayer ---@type mFramework.CustomPlayer
    if To == ('Server' or 'server') then
        thisPlayer = System.GetEntity( g_localActorId )
        return thisPlayer:SendEventToServer( Event, (source_Id or false), (target_Id or false) )
    elseif To == ('allClients' or 'allclients') then
        if CryAction.IsDedicatedServer() then
            thisPlayer = GetRandomPlayer()
        else
            thisPlayer = System.GetEntity( g_localActorId )
        end
        return thisPlayer:SendEventToClient( Event, (source_Id or false), (target_Id or false), true )
    elseif type( To ) == 'userdata' then
        thisPlayer = System.GetEntity( To )
        if thisPlayer.SendEventToClient then
            return thisPlayer:SendEventToClient( Event, (source_Id or false), (target_Id or false) )
        end
    end
end
