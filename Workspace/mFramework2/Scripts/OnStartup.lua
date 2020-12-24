--- this file gets called during OnInitPreLoaded() and is used to initialise mFramework2 Systems
local log_tag = 'mFramework2/Scripts/OnStartup.lua' -- this files logging identifier

mFramework.Log(log_tag,'Load: PluginManager...')
local PluginManager = require('mFramework2.Systems.PluginManager')
local pm = PluginManager() ---@type mPluginManager
if (not pm) then
    mFramework.Err(log_tag, 'Failed to init PluginManager')
    return
else
    mFramework.Log(log_tag,'PluginManager Loaded!')
    mFramework.PluginManager = pm
end