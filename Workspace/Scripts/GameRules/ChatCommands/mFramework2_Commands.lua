--- mFramework Status Command
---| Outputs mFramework status
---@type ChatCommand
ChatCommands['!mf-status'] = function(playerId, command)
    local message = string.format('[mFramework] -> Initialised: %s | Started: %s', tostring(g_mFramework.state["initialised"]),tostring(g_mFramework.state["started"]))
    g_gameRules.game:SendTextMessage(4, playerId, message)
end