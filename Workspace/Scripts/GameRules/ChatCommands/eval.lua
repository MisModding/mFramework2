ChatCommands['!eval'] = function(playerId, command)

    local player = System.GetEntity(playerId)

    player:SendEventToClient {type = 'runScript', data = {script = command or 'Log(\'no command\')'}}

end
