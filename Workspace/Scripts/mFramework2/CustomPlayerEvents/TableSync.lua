local event = {
    type = '@TableSync',
    method = function( playerId, event, source_id, target_id )
        if (not type( event ) == 'table') then
            Log( 'SKIPPED - Invalid event Data' )
            return
        end
        local eventData = event.data
        local SynchedTable = {}
        local RemoteTable = event.payload
        local targetEntity = target_id
        local targetClass = event.class
        local TableTarget = nil
        Log( 'Recieved TableSync Event > Processing...' )
        if not targetClass and (type( targetEntity ) == 'userdata') then
            Log( '   > Target Appears to Be a specified Entity' )
            TableTarget = System.GetEntity( targetEntity )
        elseif type( targetClass ) == 'string' and (targetClass ~= '') then
            Log( '   > Target Appears to Be a Class or Table' )
            TableTarget = _G[targetClass]
        end

        if TableTarget and type( TableTarget ) == 'table' then
            ---@diagnostic disable-next-line: undefined-field
            local tableClass = (TableTarget.class or targetClass)
            Log( '   > Found Target: %s', (tableClass) )
            _G[tableClass] = mergef( TableTarget, RemoteTable, true )
        end
    end,
}
InsertIntoTable( g_CustomPlayerEvents, event )

--
-- ─── METHODS ────────────────────────────────────────────────────────────────────
--

--- * Sync a table to a specified class or entity on a remote client
---@param player table entity - player entity of client to sync
---@param target table|userdata classname|entityId of the class/entity to Sync
---@param tbl table table containing the keys/tables to replicate to the remote client
--- Note tbl does not support functions (though you can serialise it somehow and send it as string to loadsting on the client)
function mSyncRemoteEntitityTableForClient( player, target, tbl )
    if type( target ) == 'userdata' then
        return mSendEvent( player.id, {Type = '@TableSync', Data = {payload = tbl}}, false, target )
    elseif type( target ) == 'string' and (target ~= '') then
        return
          mSendEvent( player.id, {Type = '@TableSync', Data = {class = target, payload = tbl}} )
    end
end

--- * Sync a table to a specified class or entity to ALL Connected clients
---@param target table|userdata classname|entityId of the class/entity to Sync
---@param tbl table table containing the keys/tables to replicate to the remote client
--- Note tbl does not support functions (though you can serialise it somehow and send it as string to loadsting on the client)
function mSyncRemoteEntitityTableAllClients( target, tbl )
    if type( target ) == 'userdata' then
        return mSendEvent( 'allClients', {Type = '@TableSync', Data = {payload = tbl}}, false,
                 target )
    elseif type( target ) == 'string' and (target ~= '') then
        return mSendEvent( 'allClients',
                 {Type = '@TableSync', Data = {class = target, payload = tbl}} )
    end
end
