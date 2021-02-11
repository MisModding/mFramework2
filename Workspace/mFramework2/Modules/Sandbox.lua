if not _G['Class'] then require('libs.MisCommon') end

NULL = {nil, nil}

local LuaFuncs = {}
function LuaFuncs.loadLuaString(str, env)
    local f, e = loadstring(str, str)
    if f and env then setfenv(f, env) end
    return unpack({f, e})

end
function LuaFuncs.loadLuaFile(filename, env)
    local f, e = loadfile(filename)
    if f and env then setfenv(f, env) end
    return unpack({f, e})
end
function LuaFuncs.luaGetEnv(level, thread)
    local info = (thread and debug.getinfo(thread, level + 1, 'f')) or debug.getinfo(level + 1, 'f')
    local func = assert(info.func)
    return getfenv(func)
end

local ErrorLog = function(msg, ...)
    Log('[Sandbox:Error]>')
    Log(msg, ...)
end

---@class Sandbox
---@field Env table `Sandbox Environment __index set to _G`
local Sandbox = Class()

function Sandbox:new()
    local sandbox_env = {}
    for k, v in pairs(_G) do sandbox_env[k] = _G[k] end
    self.Env = sandbox_env
end

function Sandbox:Mutate(env)
    if type(env) == 'table' then
        for k, v in pairs(env) do
            if v == NULL then
                self.Env[k] = nil
            else
                self.Env[k] = v
            end
        end
    end
end

function Sandbox:runScript(luaString, ...)
    local arg = {...}
    local env = setmetatable({}, {__index = self.Env})
    return xpcall(function()
        local runOk, result = pcall(LuaFuncs.loadLuaString(luaString, env))
        if runOk then
            local loader
            if (type(result) == 'table') and (type(result['loader']) == 'function') then
                loader = result.loader
            elseif type(result) == 'function' then
                loader = result
            end

            if loader then
                setfenv(loader, env)
                local loaderResult = loader(unpack(arg))
                if loaderResult then
                    -- delete the loader if exists in result
                    if (loaderResult == 'table') and (loaderResult['loader'] == result['loader']) then
                        loaderResult['loader'] = nil
                    end
                end
                status, result = true, loaderResult
            end
        else
            status, result = false, 'Failed to run Script'
        end
        setmetatable(env, nil)
        return status, (result or 'Success running Script')
    end, function(E)
        local E_header = [[
                [LoadScript] error: %s
                script:
                ]]
        return ErrorLog(string.format(E_header, E) .. '%s', luaString)
    end)
end

function Sandbox:runFile(filepath, ...)
    local arg = {...}
    return xpcall(function()
        local fileOk, file = pcall(function() return io.open(filepath, 'r') end)
        if fileOk and file then
            local readOk, content = pcall(function() return file:read('*a') end)
            file:close()
            if readOk and (type(content) == 'string') then
                local runOk, status, result = self:runScript(content, unpack(arg))
                if runOk then return result, status end
            end
        end
    end, function(E) return ErrorLog('[LoadFile] error: %s file: %s', E, filepath) end)
end

RegisterModule('mFramework2.Classes.Sandbox', Sandbox)
return Sandbox
