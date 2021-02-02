local DataStore = require('mFramework2.Classes.DataStore')

--- Create mFramework Public interface
local function CreatePublicInterface()
    ---@class mFramework
    --- mFramework Public class
    ---| g_mFramework will be our index
    mFramework2 = {}
    g_mFramework.PersistantStorage = DataStore { persistance_dir = 'mFramewor2/PersistantStorage'} ---@type DataStore
    setmetatable(mFramework2, {__index = g_mFramework})
    return true
end

--- Create mFramework Standard Events
local function CreateStandardEvents()
    mFramework2.Events:observe('mFramework2:OnPreLoaded',
                              ( -- >> Called after mFramework Core has PreLoaded esential classes/modules
    function(event, data, ...)
        --- Output to DebugLog
        mFramework2.Debug(event.type, 'Stage reached...')
        return true
    end), true)

    mFramework2.Events:observe('mFramework2:OnAllLoaded',
                              ( -- >> Called after mFramework Core has fully Loaded
    function(event, data, ...)
        --- Output to DebugLog
        mFramework2.Debug(event.type, 'Stage reached...')
        return true
    end), true)

    mFramework2.Events:observe('mFramework2:OnShutdown',
                              ( -- >> Called after mFramework Core has unLoaded
    function(event, data, ...)
        --- Output to DebugLog
        mFramework2.Debug(event.type, 'Stage reached...')
        return true
    end), true)
    return true
end

--- Create mFramework Standard Interface
local function CreateStandardInterface()
    function mFramework2:Init(init_time)
        -- save init time
        self.state['initialised'] = init_time
        -- setup CustomEntity Support
        Script.ReloadScript(FS.joinPath(self.BASEDIR, 'CustomEntity.lua'))
        -- Setup our CustomPlayer
        Script.ReloadScript(FS.joinPath(self.BASEDIR, 'CustomPlayer.lua'))
        -- Load CustomEntities
        Script.LoadScriptFolder(FS.joinPath(self.BASEDIR, 'CustomEntities'))
        -- Load Systems
        Script.LoadScriptFolder(FS.joinPath(self.BASEDIR, 'Systems'))
        if System.IsEditor() then ReExposeAllRegistered() end
        self.Events:emit('mFramework2:OnPreLoaded', {initialised = init_time})
        mFramework2.Log('mFramework', 'mFramework Initialised...')
    end

    function mFramework2:Start(start_time)
        -- save start time
        self.state['started'] = start_time
        Script.ReloadScript(
            FS.joinPath(self.BASEDIR, 'Scripts', 'OnStartup.lua'))
        ReExposeAllRegistered()
        self.Events:emit('mFramework2:OnAllLoaded', {started = start_time})
        mFramework2.Log('mFramework', 'mFramework Started...')
    end

    function mFramework2:Shutdown(shutdown_time)
        -- save start time
        self.state['stopped'] = shutdown_time
        Script.ReloadScript(FS.joinPath(self.BASEDIR, 'Scripts',
                                        'OnShutdown.lua'))
        self.Events:emit('mFramework2:OnShutdown', {stopped = shutdown_time})
        mFramework2.Log('mFramework', 'mFramework Stopping...')
    end

    -- Register Init Callback
    RegisterCallback(_G, 'OnInitPreLoaded', nil,
                     function() mFramework2:Init(os.date()) end)

    -- Register Start Callback
    RegisterCallback(_G, 'OnInitAllLoaded', nil,
                     function() mFramework2:Start(os.date()) end)

    -- Register Shutdown Callback
    RegisterCallback(_G, 'OnShutdown', nil,
                     function() mFramework2:Shutdown(os.date()) end)

    return true
end

local function init()
    if (not CreatePublicInterface()) then
        LogError('mFramework2:main failed @ stage: CreatePublicInterface()')
        return
    end
    if (not CreateStandardEvents()) then
        LogError('mFramework2: init failed @ stage: CreateStandardEvents')
        return
    end
    if (not CreateStandardInterface()) then
        LogError('mFramework2: init failed @ stage: CreateStandardInterface()')
        return
    end
    ---TODO: Improve logging
    -- >> Currently using a simple wrapper to handle logging, we should improve this to include more info.
end

OnlyRunOnce(init)
