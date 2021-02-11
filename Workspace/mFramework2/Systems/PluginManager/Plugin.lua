local Sandbox = require('mFramework2.Classes.Sandbox')

local PluginSandbox = Sandbox() ---@type Sandbox
PluginSandbox:Mutate{debug = NULL}
---@class mPlugin2
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
    local loaded, result = PluginSandbox:runFile(pluginFile)
    if (not loaded) then
        return false, string.expand('failed to compile plugin file: ${file} > ${result}',
                                    {file = pluginFile, result = tostring(result)})
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

RegisterModule('mFramework2.Systems.PluginManager.Plugin', mPlugin)
return mPlugin
