--
-- ──────────────────────────────────────────────────────────────────────────── I ──────────
--          :::::: m F r a m e w o r k  S T A R T U P   F I L E ::::::
-- ──────────────────────────────────────────────────────────────────────────────────────
--- mFramework Global Namespace.
g_mFramework = {
    --- mFramework
    _NAME = 'mFramework',
    --- mFramework Version
    _VERSION = '0.1.0a',
    --- mFramework Description
    _DESCRIPTION = [[
        mFramework2 
            a Miscreated Mod Development Framework.
        - made with MisModWorkspace.
    ]],
    LOGLEVEL = 1,
    LOGFILE = './mFramework2.log',
    --- mFramework BaseDir
    BASEDIR = 'mFramework2/',
    --- mFramework global classes
    classes = {}, ---@type table<string,any>
    --- mFramework global modules
    modules = {}, ---@type table<string,table>
    --- mFramework global plugins
    plugins = {}, ---@type table<string,table>
    --- mFramework global state
    state = {
        --- mFramework Init Time
        initialised = false, ---@type boolean|table
        --- mFramework Start Time
        started = false, ---@type boolean|table
    },
}

if System.IsEditor() then g_mFramework.LOGLEVEL = 3 end

-- > load common files
Script.ReloadScript(
 g_mFramework.BASEDIR .. 'Common.lua'
)
Script.LoadScriptFolder(
 g_mFramework.BASEDIR .. 'Common/'
)

Script.LoadScriptFolder('MisDB2/')
MisDB = require("MisDB2.MisDB")

Script.LoadScriptFolder(
 g_mFramework.BASEDIR .. 'Modules/'
)

--- mFramework Event Manager
g_mFramework.Events = require("mFramework2.Modules.Events")

Script.LoadScriptFolder(
 g_mFramework.BASEDIR .. 'Classes/'
)

Script.ReloadScript(
 g_mFramework.BASEDIR .. 'main.lua'
)
