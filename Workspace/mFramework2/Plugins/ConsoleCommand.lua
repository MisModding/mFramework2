local function split_command(str, delimiter)
    local result = {}
    local from = 1
    local delim = delimiter or ' '
    local delim_from, delim_to = string.find(str, delim, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local function parse_kvargs(str)
    local t = {}
    -- note: currently only supports 3 spaces or 3 punctuation symbols in a value
    for k, v in string.gmatch(str, '-(%w+)=(%w+%p?%s?%w+%p?%s?%w+)') do t[k] = v end
    return t
end

local parseCommand = function(command)
    local parsed = {}
    local command_parts = split_command(command)
    if command_parts then
        parsed.cmd = command_parts[1]
        parsed.arg0 = command:gsub(command_parts[1], ''):gsub('^%s', '')
        parsed.args = command_parts
        table.remove(parsed.args, 1)
        parsed.kvargs = parse_kvargs(command)
        ---HACK: cleanup any kvargs from args
        for k in pairs(parsed['kvargs']) do
            for i, value in ipairs(parsed['args']) do
                if string.find(value, '-' .. k) then table.remove(parsed.args, i) end
            end
        end
        return parsed
    else
        return command
    end
end

local SetupConsoleHandler = function()
    if not g_scriptCommands then g_scriptCommands = {} end

    --- RegisterScriptCommand
    ---comment
    ---@param command   string                                      `command to register`
    ---@param method    fun(commandData:table):boolean,string       `command method`
    ---@return boolean  `true if successfull or false`
    ---@return string   `error message`
    function RegisterScriptCommand(command, method)
        local cmd = FindInTable(g_scriptCommands, 'scriptCommand', command)
        if cmd then return false, 'command exists' end
        InsertIntoTable(g_scriptCommands, {scriptCommand = command, commandMethod = method})
        return true, 'command registered'
    end

    --- g_handleConsoleScriptCommand
    function g_handleConsoleScriptCommand(command)
        local cmdData = parseCommand(command)
        local action = cmdData['cmd']
        local scriptCommand = FindInTable(g_scriptCommands, 'scriptCommand', action)
        if (not scriptCommand) then return end
        local method = scriptCommand['commandMethod']
        local ok, result = method(cmdData)
        if ok == true then
            Log('scriptCommand: %s > OK: %s', action, result)
        else
            LogWarning('scriptCommand: %s > ERROR: %s', action, result)
        end
    end

    local CCommand = {
        command = 'mod_command',
        method = 'g_handleConsoleScriptCommand(%1)',
        helptext = 'Executes Registered scriptCommands: mod_command "[command] [params]"',
    }
    System.AddCCommand(CCommand.command, CCommand.method, CCommand.helptext);
end

SetupConsoleHandler()