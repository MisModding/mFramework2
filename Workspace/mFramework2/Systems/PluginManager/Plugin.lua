local luaLoadFile = function(fPath)
    local file, script
    if fPath then
        file = io.open(fPath, 'r')
        if (not file) or (not file.read) then return false, string.format('failed to read from file: %s', fPath) end
        script = file:read('*a')
        file:close()
        if (not script) then return false, 'no file content' end
        return (function() return pcall(loadstring, script) end)()
    end
    return false, 'no path given'
end

---@class mPlugin
---@field new fun(self:mPlugin,pluginPath:string):mPlugin|nil,string
local mPlugin = Class {}

function mPlugin.new(self, pluginPath)
    if assert_arg(1, pluginPath, 'string') then
        return nil, 'invalid pluginPath or no path given'
    elseif (not FS.Exists(pluginPath)) then
        return nil, string.expand('unknown or invalid path: ${path}', {path = pluginPath})
    end
    local pluginFile = FS.joinPath(pluginPath, 'plugin.lua')
    if (not FS.isFile(pluginFile)) then return nil, string.expand('failed to find pluginFile: ${file}', {file = pluginFile}) end
    local loaded, result = luaLoadFile(pluginFile)
    if (not loaded) then
        return false, string.expand(
                'failed to compile plugin file: ${file} > ${result}', {file = pluginFile, result = tostring(result)}
               )
    else
        result = result()
        if (not result.name) then return false, 'no plugin name defined' end
        if (not result.description) then return false, 'no plugin description defined' end
        if (not result.version) then return false, 'no plugin version defined' end
        local _, sourceFile = FS.readFile(pluginFile)
        self.path = pluginFile
        self.source = sourceFile
        self.plugin = result
    end
end

function mPlugin:dump() return self['source'] end

RegisterModule("mFramework2.Systems.PluginManager.Plugin",mPlugin)
return mPlugin
