local M = {
    _NAME = 'mWebClient',
    _VERSION = '0.1-dev',
    _DESCRIPTION = [[
Provides Basic GET/POST Supprt for CE3 Game Modules
the lua environment found in CE3 games doesnt allow for loading common dll based http libraries
this module attempts to get around this by using native windows powershell calls and coroutines
]],
}

local print,setmetatable = print,setmetatable

if setfenv then
    setfenv(1, M) -- for 5.1
else
    _ENV = M -- for 5.2
end

local read_file
read_file = function(path)
    local fh = io.open(path)
    local data = fh:read('*a')
    fh:close()
    return data
end
local write_file
write_file = function(path, data)
    local fh = io.open(path, 'w')
    fh:write(data)
    return fh:close()
end
local exec
exec = function(cmd, input, capture)
    local input_path = os.getenv('TEMP') .. os.tmpname()
    local output_path = os.getenv('TEMP') .. os.tmpname()
    os.remove(input_path)
    os.remove(output_path)
    if input then
        write_file(input_path, input)
        cmd = cmd .. ' < ' .. input_path
    else
        cmd = cmd
    end
    if capture then cmd = cmd .. ' > ' .. output_path end
    cmd = string.format('start /MIN "mServerAdminHelper" ' .. ' "cmd /C %s"', cmd)
    local execOK = os.execute(cmd)
    if capture then
        return output_path
    else
        return execOK
    end
end

local Format = {}
Format.arrayTag = {}
function Format.makeExplicitArray(arr)
    if arr == nil then arr = {} end
    arr[Format.arrayTag] = true
    return arr
end
local indentStr = '  '
local escapes = {
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['"'] = '\\"',
    ['\\'] = '\\' .. '\\',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\t'] = '\\t',
    ['\0'] = '\\u0000',
}
local escapesPattern = '[\n\r"\\\b\f\t%z]'
local function escape(str)
    local escaped = str:gsub(escapesPattern, escapes)
    return escaped
end
local function isArray(val)
    if val[Format.arrayTag] then return true end
    local len = rawlen(val)
    if len == 0 then return false end
    for k in pairs(val) do if (type(k) ~= 'number') or (k > len) then return false end end
    return true
end
function Format.asJson(val, indent, tables)
    if indent == nil then indent = 0 end
    tables = tables or ({})
    local valType = type(val)
    if (valType == 'table') and (not tables[val]) then
        tables[val] = true
        if isArray(val) then
            local arrayVals = {}
            for _, arrayVal in ipairs(val) do
                local valStr = Format.asJson(arrayVal, indent + 1, tables)
                table.insert(arrayVals,
                  ('\n' .. tostring(indentStr:rep(indent + 1))) .. tostring(valStr))
            end
            return ((('[' .. tostring(table.concat(arrayVals, ','))) .. '\n') ..
                     tostring(indentStr:rep(indent))) .. ']'
        else
            local kvps = {}
            for k, v in pairs(val) do
                local valStr = Format.asJson(v, indent + 1, tables)
                table.insert(kvps,
                  (((('\n' .. tostring(indentStr:rep(indent + 1))) .. '"') ..
                    tostring(escape(tostring(k)))) .. '": ') .. tostring(valStr))
            end
            return ((#kvps > 0) and
                     (((('{' .. tostring(table.concat(kvps, ','))) .. '\n') ..
                       tostring(indentStr:rep(indent))) .. '}')) or '{}'
        end
    elseif (valType == 'number') or (valType == 'boolean') then
        return tostring(val)
    else
        return ('"' .. tostring(escape(tostring(val)))) .. '"'
    end
end
function Format.asHashTable(jsonString)
    if not type(jsonString) == 'string' then return end
    local stage1 = jsonString:gsub('\\"', '"'):gsub('"{', '@{ '):gsub('}"', ' }'):gsub(',', '; ')
                     :gsub(':', '=')
    local stage2 = stage1:gsub('@{ "', '@{ '):gsub('" } ', ' } ')
    local result = stage2:gsub('"="', '="'):gsub('; "', '; ')
    return result:gsub('"', '\'')
end

local string_tformat
string_tformat =
  function(s, tmpl) for key, arg in pairs(tmpl) do s = {s = string.gsub(key, arg)} end end
local cleanOutput
cleanOutput = function(str)
    local s = ''
    s = str:gsub('\r\n', ''):gsub('\n', '')
    return s
end

asJSON = Format.asJson

asHashTable = Format.asHashTable

ValidRequest = function()
    -- TODO: Actualy Validate the request
    return true
end

CreateRequest = function(thisReq, req)
    local baseCmd = thisReq['cmd']
    local endpoint = ''
    if not (type(req[1]) ~= 'string') then endpoint = req[1] end
    thisReq['cmd'] = baseCmd:gsub('$ENDPOINT', tostring(endpoint))
    if not (type(req['Headers']) ~= 'table') then thisReq['head'] = asJSON(req['Headers']) end
    if not (type(req['Body']) ~= 'table') then thisReq['body'] = asJSON(req['Body']) end
end

SendRequest = function(cmd, args, isAsync)
    local payload = cleanOutput(args.cmd)
    local header = ''
    if args['head'] ~= '' then
        header = asJSON(args['head'])
        header = '-Headers ' .. asHashTable(header)
    end
    payload = payload:gsub('$HEADERS', header)
    local body = ''
    if args['body'] ~= '' then
        body = asJSON(args['body'])
        body = ('-Body ' .. body):gsub('\\"', '"'):gsub('"{', '\'{'):gsub('}"', '}\'')
    end
    payload = payload:gsub('$BODY', body)
    local result = exec(cmd, payload, isAsync);
    (Log or print)('$5 Executing Request: ' .. tostring(payload))
    return result
end

AwaitResponse = function(cb, res, ...)
    local AsyncTasks = require('mFramework2.Modules.AsyncTasks')
    return await(async(function()
        local done = nil
        local result
        timout = 10
        starttime = os.clock()
        local currentTime
        while not done do
            result = ''
            currentTime = os.clock()
            if (currentTime - starttime) > timout then
                Log('Debug> timout')
                return
            end
            local ok
            ok, result = read_file(res)
            if (not ok) or (string.len(result) == 0) then
                ---@diagnostic disable-next-line: undefined-global
                task_yield()
            else
                ok, result = read_file(res)
                os.remove(res)
                done = true
                result = cleanOutput(result)
            end
        end
        return cb(result, unpack(arg))
    end))
end

local WebClient
do
    local _class_0
    local _base_0 = {
        proc = '@powershell -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -Command -',
        cmdline = 'Invoke-WebRequest -Uri \'$URI\' -Method $METHOD -ContentType \'$CONTENT_TYPE\' $HEADERS $BODY | Select-Object -ExpandProperty Content',
        get = function(self, req, cb, isAsync)
            if not (type(req) == 'table') then return end
            local thisReq = {cmd = self.cmdline:gsub('$METHOD', 'GET'), head = '', body = ''}
            CreateRequest(thisReq, req)
            if not (ValidRequest(thisReq) == false) then
                local result = SendRequest(self.__class.proc, thisReq, isAsync)
                if type(cb) == 'function' then return cb(result) end
                return result
            end
        end,
        post = function(self, req, cb, isAsync)
            if not (type(req) == 'table') then return end
            local thisReq = {cmd = self.cmdline:gsub('$METHOD', 'POST'), head = '', body = ''}
            CreateRequest(thisReq, req)
            if not (ValidRequest(thisReq) == false) then
                local result = SendRequest(self.__class.proc, thisReq, isAsync)
                if type(cb) == 'function' then return cb(result) end
                return result
            end
        end,
        getAsync = function(self, req, cb, ...)
            local res = self:get(req, nil, true)
            return AwaitResponse(cb, res, ...)
        end,
        postAsync = function(self, req, cb, ...)
            local res = self:post(req, nil, true)
            return AwaitResponse(cb, res, ...)
        end,
    }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
        __init = function(self, uri)
            self.uri = uri
            if not (type(self.uri) == 'string') then return end
            self.cmdline = self.__class.cmdline:gsub('$URI', self.uri .. '$ENDPOINT')
            self.cmdline = self.cmdline:gsub('$CONTENT_TYPE', 'application/json')
        end,
        __base = _base_0,
        __name = 'WebClient',
    }, {
        __index = _base_0,
        __call = function(cls, ...)
            local _self_0 = setmetatable({}, _base_0)
            cls.__init(_self_0, ...)
            return _self_0
        end,
    })
    _base_0.__class = _class_0
    WebClient = _class_0
end
M.client = WebClient
return M