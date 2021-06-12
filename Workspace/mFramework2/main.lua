local MisDB = require "MisDB"
local DataStore = MisDB.DataStore ---@type MisDB.DataStore

--- Load mFramework Core
local function Load_mFramework_Core()
    --- mFramework Public class
    ---@class mFramework
    ---@field state table `Current State of this mFramework Instance`
    mFramework2 = {}
    ---@type MisDB.DataStore
    g_mFramework.PersistantStorage = DataStore {
        name = 'mFramework2',
        persistance_dir = 'PersistantStorage',
    }

    --- g_mFramework will be our index
    setmetatable( mFramework2, {__index = g_mFramework} )
    return true
end

--- Create mFramework Standard Events
local function CreateStandardEvents()
    -- >> Called after mFramework Core PreLoads esential classes/modules
    mFramework2.Events:observe( 'mFramework2:OnPreLoaded', function( event, data, ... )
        --- Output to DebugLog
        mFramework2.Debug( event.type, 'Stage reached...' )
        return true
    end, true )

    -- >> Called after mFramework Core has fully Loaded
    mFramework2.Events:observe( 'mFramework2:OnAllLoaded', function( event, data, ... )
        --- Output to DebugLog
        mFramework2.Debug( event.type, 'Stage reached...' )
        return true
    end, true )

    return true
end

--- mFramework Standard Interface
local function CreateStandardInterface()
    -- Create and Register Init Callback
    function mFramework2:Init( init_time )
        -- setup CustomEntity Support
        Script.ReloadScript( FS.joinPath( self.BASEDIR, 'CustomEntity.lua' ) )
        -- Setup our CustomPlayer
        Script.ReloadScript( FS.joinPath( self.BASEDIR, 'CustomPlayer.lua' ) )
        -- Load CustomEntities
        Script.LoadScriptFolder( 'Scripts/mFramework2/CustomEntities' )
        -- >> in editor we need to ReExpose Registered CustomEntities extra early else stuff wont work properly
        if System.IsEditor() then ReExposeAllRegistered() end

        g_AsyncTasks = require( 'mFramework2.Modules.AsyncTasks' )

        --- fetch a mFramework Player object for the given Miscreated Player
        ---@param player player
        ---@return mFramework.Player
        self.GetPlayer = function(player)
            local mPlayer = require("mFramework2.Classes.Player")
            return mPlayer(player) ---@type mFramework.Player
        end

        -- save init time
        self.state['initialised'] = init_time

        -- emit OnPreloadedEvent passing our final init time
        self.Events:emit( 'mFramework2:OnPreLoaded', {initialised = init_time} )
        mFramework2.Log( 'mFramework', 'mFramework Initialised...' )
    end

    RegisterCallback( _G, 'OnInitPreLoaded', nil, function() mFramework2:Init( os.date() ) end )

    -- Create and Register Start Callback
    function mFramework2:Start( start_time )
        ReExposeAllRegistered()
        Script.LoadScriptFolder( 'mFramework2/Plugins' )
        g_AsyncTasks:Start()
        -- save start time
        self.state['started'] = start_time
        self.Events:emit( 'mFramework2:OnAllLoaded', {started = start_time} )
        mFramework2.Log( 'mFramework', 'mFramework Started...' )
    end
    RegisterCallback( _G, 'OnInitAllLoaded', nil, function() mFramework2:Start( os.date() ) end )

    return true
end

local function init()
    if (not Load_mFramework_Core()) then
        LogError( 'mFramework2:main failed @stage: Load mFramework Core' )
        return
    end
    if (not CreateStandardEvents()) then
        LogError( 'mFramework2: init failed @stage: CreateStandardEvents' )
        return
    end
    if (not CreateStandardInterface()) then
        LogError( 'mFramework2: init failed @stage: CreateStandardInterface' )
        return
    end
    ---TODO: Improve logging
    -- >> Currently using a simple wrapper to handle logging, we should improve this to include more info.
end

OnlyRunOnce( init )