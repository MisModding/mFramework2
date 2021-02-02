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
        parsed.args = {command_parts[2], command_parts[3]}
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

---@class mChatCommand
---@field   cmd         string                                  Command
---@field   name        string                                  Command Name
---@field   description string                                  Command Description
---@field   usage       string                                  Command Usage help
---@field   method      function                                Command Main Method
---@field   new         fun(self:ChatCommand):ChatCommand       Create a New ChatCommand
--- Create a new ChatCommand using the mFramwork ChatHandler
local ChatCommand = {}
local meta = {
    __index = ChatCommand,
    __call = function(self, ...)
        local cmd = {}
        setmetatable(cmd, {__index = self})
        return self.new(cmd, ...)
    end,
}
setmetatable(ChatCommand, meta)
function ChatCommand:new(cmd)
    self.cmd = cmd
    return self
end

function ChatCommand:reply(player,msg)
    if (not player.player) then return end
    local template = "  Command: ${command} > \n    Response: ${content}"
    g_gameRules.game:SendTextMessage(0, player._id, string.expand(template,{command = self.name, content = msg}))
end

function ChatCommand:run(player, command, ...)
    if (not type(self['method']) == 'function') then return false, 'Command has no method' end
    local cmd = parseCommand(command)
    local ok, response = self:method(cmd, ...)
    if type(response) == "string" then
        if type(self["reply"]) == "function" then
            self:reply(player,response)
        end
    end
    return ok,response
end

mFramework2.ChatCommand = ChatCommand