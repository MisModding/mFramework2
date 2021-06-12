event = {
    type = '@ClientEval',
    method = function( playerId, event )
        local data = event.data
        if (not event) then
            return
        elseif (not type( data.eval ) == 'string') then
            Log( 'eval string not found' )
            return
        else
            Log( 'Client Eval >>' )
            Log( '   eval_string: ' .. data.eval )

            local evalOk, result = eval_string( data.eval )
            if result then return result end
        end
    end,
}
InsertIntoTable( g_CustomPlayerEvents, event )
