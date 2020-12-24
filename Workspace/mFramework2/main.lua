--- Create mFramework Public interface
local function CreatePublicInterface()
    ---@class mFramework
    --- mFramework Public class
    ---| g_mFramework will be our index
    mFramework = {}
    --- mFramework Event Manager
    mFramework.Events = g_mFramework.Events
    setmetatable(mFramework, {__index = g_mFramework})
    return true
end

--- Create mFramework Essential Events
local function CreateStandardEvents()
    mFramework.Events:observe('mFramework:OnPreLoaded',
                              ( -- >> Called after mFramework Core has been fully PreLoaded
    function(event, data, ...)
        --- Output to DebugLog
        mFramework.Debug(event.type, 'Stage reached...')
        return true
    end), true)

    mFramework.Events:observe('mFramework:OnAllLoaded',
                              ( -- >> Called after mFramework Core has been fully Loaded
    function(event, data, ...)
        --- Output to DebugLog
        mFramework.Debug(event.type, 'Stage reached...')
        return true
    end), true)

    mFramework.Events:observe('mFramework:OnShutdown',
                              ( -- >> Called after mFramework Core has been fully Loaded
    function(event, data, ...)
        --- Output to DebugLog
        mFramework.Debug(event.type, 'Stage reached...')
        return true
    end), true)
    return true
end

--- Create mFramework Standard Interface
local function CreateStandardInterface()
    function mFramework:Init(init_time)
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
        self.Events:emit('mFramework:OnPreLoaded', {initialised = init_time})
        mFramework.Log('mFramework', 'mFramework Initialised...')
    end

    function mFramework:Start(start_time)
        -- save start time
        self.state['started'] = start_time
        Script.ReloadScript(
            FS.joinPath(self.BASEDIR, 'Scripts', 'OnStartup.lua'))
        ReExposeAllRegistered()
        self.Events:emit('mFramework:OnAllLoaded', {started = start_time})
        mFramework.Log('mFramework', 'mFramework Started...')
    end

    function mFramework:Shutdown(shutdown_time)
        -- save start time
        self.state['stopped'] = shutdown_time
        Script.ReloadScript(FS.joinPath(self.BASEDIR, 'Scripts',
                                        'OnShutdown.lua'))
        self.Events:emit('mFramework:OnShutdown', {stopped = shutdown_time})
        mFramework.Log('mFramework', 'mFramework Stopping...')
    end

    -- Register Init Callback
    RegisterCallback(_G, 'OnInitPreLoaded', nil,
                     function() mFramework:Init(os.date()) end)

    -- Register Start Callback
    RegisterCallback(_G, 'OnInitAllLoaded', nil,
                     function() mFramework:Start(os.date()) end)

    -- Register Shutdown Callback
    RegisterCallback(_G, 'OnShutdown', nil,
                     function() mFramework:Shutdown(os.date()) end)

    return true
end

local function init()
    if (not CreatePublicInterface()) then
        LogError('mFramework:main failed @ stage: CreatePublicInterface()')
        return
    end
    if (not CreateStandardEvents()) then
        LogError('mFramework: init failed @ stage: CreateStandardEvents')
        return
    end
    if (not CreateStandardInterface()) then
        LogError('mFramework: init failed @ stage: CreateStandardInterface()')
        return
    end
    ---TODO: Improve logging
    -- >> Currently using a simple wrapper to handle logging, we should improve this to include more info.
end

OnlyRunOnce(init)
