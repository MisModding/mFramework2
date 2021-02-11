local Events = require('mFramework2.Modules.events')
Script.LoadScriptFolder(FS.joinPath(mFramework2.BASEDIR, 'Systems', 'PluginManager'))
local Plugin = require('mFramework2.Systems.PluginManager.Plugin')

---@class mPluginManager
---@field new fun():mPluginManager
local plugin_manager = Class {}

---Create a new PluginManager Instance
function plugin_manager:new()
    self.events = Events()
    self.plugins = {}
    return self
end

---loads a plugin from a given path
-- | name must match the loaded plugin else will fail
---@param name string name of plugin to load
---@param path string path to the given plugin folder
---@return boolean
---@return mPlugin2
function plugin_manager:loadPlugin(name, path)
    local result = Plugin(path)
    if (not result) then return false, result end
    if (not result) then return false, 'plugin failed to load: returned nil' end
    local plugin = result.plugin
    if (plugin.name ~= name) then return false, 'provided plugin name does not match the loaded plugin' end
    table.insert(self['plugins'], result)
    if type(plugin['onLoad']) == 'function' then plugin.onLoad() end
end

function plugin_manager:listPlugins()
    local plugin_list = {}
    for _, plugin in pairs(self['plugins']) do
        if (type(plugin['plugin']) ~= 'table') then break end
        local this = plugin['plugin']
        local entry = {
            plugin_file = (plugin['path'] or 'unKnown'),
            plugin_description = (this['description'] or 'unKnown'),
            plugin_hasLoadMethod = (type(this['onLoad']) == 'function'),
            plugin_hasUnloadMethod = (type(this['onUnload']) == 'function'),
        }
        plugin_list[this.name] = entry
    end
    return plugin_list
end

function plugin_manager:getPlugin(name)
    for _, entry in pairs(self['plugins']) do
        local plugin = entry.plugin
        if plugin['name'] == name then return entry end
    end
    return nil
end

function plugin_manager:use(name)
    local thisPlugin = self:getPlugin(name)
    if thisPlugin then return thisPlugin.plugin end
    return nil
end

RegisterModule('mFramework2.Systems.PluginManager', plugin_manager)
return plugin_manager
