--[[ --
  ==========================================================================================
    File: ClientEval.lua	Author: theros#7648
    Description: description
    Created:  2021-06-11T02:38:02.840Z
    Modified: 2021-06-11T06:16:59.451Z
    vscode-fold=2
  ==========================================================================================
--]] --
ChatCommands['!ClEval'] = function( playerId, command )
    local player = System.GetEntity( playerId ) ---@type CE3.player
    if command then
        local mPlayer = mFramework2.GetPlayer( player )
        if (not mPlayer:GetPermission( 'IS_ADMIN' )) then
            g_gameRules.game:SendTextMessage( 4, playerId, 'not authorised' )
            return
        end
        player:SendEventToClient( {type = '@ClientEval', data = {eval = command}} )
    end
end
