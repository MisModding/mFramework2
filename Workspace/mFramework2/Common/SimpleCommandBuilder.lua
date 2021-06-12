--[[ --
  ==========================================================================================
    File: SimpleCommandBuilder.lua	Author: theros#7648
    Description: description
    Created:  2021-04-22T09:12:28.255Z
    Modified: 2021-05-30T20:46:15.450Z
    vscode-fold=2
  ==========================================================================================
--]] --

--- global table containing all registered authorisation handlers
g_auth_methods = {}
--- default auth method
g_default_auth_method = "admin-file"

---splits a commandString into chunks based on a specified delimiter
---@param str           string                  commandString to split
---@param delimiter     string                  pattern used as delimiter to split the given string
---@alias commandParts  table<number,string>    commandString chunks
---@return commandParts
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

    return result ---@type commandParts
end

--- extracts `-key=value` property keypairs from a given commandString
---@param str           string
---@alias   KVlist      table<string,string>            List of Key=Value pairs
---@return  KVlist
local function parse_kvargs(str)
    local t = {}
    -- note: currently only supports 3 spaces or 3 punctuation symbols in a value
    for k, v in string.gmatch(str, '-(%w+)=(%w+%p?%s?%w+%p?%s?%w+)') do t[k] = v end
    return t
end

--- attempt to parse a given commandString
--- returns a table if sucessfull.
--- returns a string when given a commandString containing no spaces
---@param command           string          commandString to parse
local parseCommand = function(command)
    ---@class parsedCommand
    local parsed = {}
    local command_parts = split_command(command)
    if command_parts then
        --- Command Trigger
        parsed.cmd = command_parts[1]
        --- commandString
        parsed.arg0 = command:gsub(command_parts[1], ''):gsub('^%s', '')
        --- Command Args
        parsed.args = command_parts
        table.remove(parsed.args, 1)
        --- Command Named Parameters
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

---* IsAdminPlayer
-- | Checks if a given steamId is listed in a `admins.txt` file in server root `MiscreatedServer/admins.txt`
-- | Will Print an Error in The log and return false if the file does not exist
-- | admins.txt should have ONE steamId per line (to help remember who is who, its also ok to use the format: name steamId )
---@param steamId string: players steam64Id
---@return boolean, string
--- if the steamid was found returns true or false plus a message if not
function IsAdminPlayer(steamId)
    -- try to open the admins.txt file
    local file = io.open('./admins.txt')
    local admins = {} -- this holds each line of the file
    local i = 0 -- keep track of the current line number
    -- did we successfully open the file (does it exist?)
    if file then
        -- yes so iterate through the lines using our lineIndex as table index
        for line in file:lines() do
            -- each iteration is a new line so increment the line index
            i = i + 1
            -- add the line content to the table
            admins[i] = line
        end
        -- Allways close the file when we are done with it to avoid file access errors.
        file:close()
        -- concat the admins table into a string delimited by `;` then use the current steamid as a pattern to match with
        if string.find(table.concat(admins, ';'), steamId) then
            -- if found then this steamId was in the file so return authorised
            return true, 'Authorised'
        else
            -- otherwise its not in the file so return false.
            return false, 'Unauthorised'
        end
    else
        local errmsg = './admins.txt file not found or failed to be read' -- generic error msg
        -- Failed to Open the File, Moan about it in ServerLog
        LogError(errmsg);
        -- then just return false and the errormsg, no file means no authorisation
        return false, errmsg
    end
    --- worst case scenario. this shouldn't ever be seen unless something realy goes wrong when trying to iterate the lines of the file.
    LogError(
        'Something went wrong. Maybe invalid characters in admins.txt or it is not a text file.')
end


---Basic check if a players steamId is listed in [serverdir]/Admins.txt
---@param player any
g_auth_methods["file-auth"] = function (player)
    if IsAdminPlayer(player) then
       return true
    end
end



local Authorise = function(player, permissions, method)
    --- Current auth method, defaults to `simple` (admin-file Admins.txt method)
    local auth_method
    ---@type boolean            isAuthorised?
    local authorised
    --- current auth_method handler
    local auth_handler
    if method then
        --pretty flimsy check that we found a valid function for specified authmethod....
        if (type(g_auth_methods[method]) == "function") then
            auth_method = g_auth_methods[method]
        else
            return false, string.format('unknown auth method: %s', method)
        end
    else
        auth_method = g_auth_methods[g_default_auth_method]
    end
    --- auth_method should be a vaild handler by now
    if (not type(auth_method) == "function") then
        return false, string.format('failed to find auth handler for method: %s', method)
    end

    return auth_method(player,permissions)
end


---@class CustomChatCommand
---@field command       string                                          `Command trigger`
---@field description   string                                          `Command description`
---@field params        table                                           `Command parameters`
---@field method        fun(this:CustomChatCommand):boolean,nil|string   `Command method returns boolean,errormsg`
local Command = {}

---@class paramDefinition
--- defines a Command parameter
---@field kind string   `type of parameter either string|number|boolean`
---@field info string   `short description`

---Create a New Command
---@param command string                                    `command`
---@param description string                                `commmand description`
---@param parameters table<string,paramDefinition>     `command parameter definition`
---@return boolean                                          `success?`
---@return string                                           `error message`
function Command:new(command, description, parameters)
    if type(command) ~= 'string' then
        return false, 'invalid param [command]'
    elseif type(command) ~= 'string' then
        return false, 'invalid param [description]'
    end
    self.command = command
    self.description = description
    self.params = {}
    if type(parameters) == 'table' then
        for name, param in pairs(parameters) do
            self.params[name] = {kind = param.kind, info = param.info}
        end
    end
    return self
end

--- Run this ChatCommand
---@param cmd_string any
---@return boolean
---@return string
function Command:run(cmd_string,...)
    if type(cmd_string) ~= 'string' then return false, 'invalid command string [cmd_string]' end
    if (not self['method']) or (not type(self['method']) == 'function') then
        return false, 'command has no valid method'
    end

    local cmd_instance = parseCommand(cmd_string)

    if (cmd_instance and cmd_instance['cmd']) then return self:method(cmd_instance,...) end
end

---Create a New Command
---@param commandString string                                    `command`
---@param description string                                `commmand description`
---@param parameters table<string,paramDefinition>          `command parameter definition`
---@return boolean                                          `success?`
---@return string                                           `error message`
function CreateChatCommand(commandString, description, parameters)
    local command = Command:new(commandString, description, parameters)

    --- attempt to check a players authorisation to use this command, you can specify an alternative authhandler to use
    function command.Authorise(player,method)
        if not command.permissions then return true end
        return Authorise(player, command['permissions'],method)
    end

    return command ---@type CustomChatCommand
end
