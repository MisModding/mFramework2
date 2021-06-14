
 Author: theros#7648
 b1-ExampleMod-mod_init.md
 Desc: example mod intro
 Created:  2021-06-14T05:36:57.098Z

---

### Example Mod: Intro
> Small tutorial going over how the example mod was creted

[Home](/mFramework2)



###### Project Structure
in effort to keep our working environment clean i try to keep all private mod resources outside of the usual `Scripts/.../...` path.<br>
the basic structure i use for mods is:<br>
- All private resources eg: classes,modules,scripts for our mod should live in their own `GameSDK/MyMod` folder<br>
  this is just a folder that sits next to `GameSDK/Scripts`
    - this can be accessed as normal eg using: `Script.ReloadScript('MyMod/main.lua')`
- A Single script in `Scripts/mods` to act as a "shim" to load our mod, this contains basic info like version description etc and will <br>
    define a global table as a namespace for our mod then setup some callbacks to load it at the right points in the games loadorder.
- ChatCommands will go into ChatCommands as usual a good idea is to use a common naming stratagy eg: `[modname].[filename].lua` <br>
    this way we are lass likely to run into naming conflicts when running multile mods.
    - so a chatcommand file named: `AdminCommands.lua` for a mod named: `MyMod` would become: `MyMod.AdminCommands.lua`
- Scripts used to define CustomEntities/CustomActions/CustomPlayerEvents etc go into the `Scripts/mFramework2` folders as specified <br>
    by mFramework and should use the same naming conventions as before... For Example:
    - CustomEntity: `Scripts/mFramework2/CustomEntities/MyMod.MyCustomEntity.lua`
    - CustomPlayerEvent: `Scripts/mFramework2/CustomPlayerEvents/MyMod.MyCustomEvent.lua`

Our resulting Project folder tree ends up looking something like this:<br>

![image-20210614073315789](images\mF2ExampleMod_FolderStructure.png)


###### Mod Loader
first thing our mod needs is a file in `Scripts/mods` to act as a shim to setup our global namespace and callbacks needed to load our mod. 
so we create a file named `mFramework2Test.lua`. _rename this for your own mods_

this file doesnt need much. but i also like to use it to define some basic version info and a description for my mods. its not needed, but... <br>
its a good idea as it makes it easier for other modders reading the code later

<br>

File: `Scripts/mods/mFramework2Test.lua`
----
_this is our mods "loader", remember the order files in scripts/mods are reloaded cannot be garunteed you shouldn't rely on any other mods or systems being loaded at this point_

first lets create a table to hold our mods name/version and other metadata
```lua
    --- Mod Information
    local mod_meta = {
        _NAME = "mFramework2Test",
        _DESCRIPTION = [[
            mFramework Example Mod
        ]],
        _VERSION = "0.0.1-alpha"
    }
```

then we should probably create a global table to use as the main "namespace" for our mod, and assign our metadate
miscreated tends to use a `g_` prefix convention for such tables so lets do the same. _just be sure to keep this unique as not to clobber existing globals_
we will also add 2 properties to track if our loadorder callbacks ran ok.
```lua
    --- mFramework2Test Namespace
    g_mFramework2Test = {
        _META = mod_meta,
        PreLoadedOk = false,
        AllLoadedOk = false
    }
```


keeping with the ideal. of _all mod resources should be kept seperate_ we need to reload a few folders to load our mods classes and modules.
you can skip the ones your dont use. but haveing at least a `Common` folder provides a quick and easy place to store common functions/global
variables in autoloaded files under `[yourModPath]/Common`
```lua
-- load common scripts
Script.LoadScriptFolder("mFramework2Test/Common")
-- load Modules
Script.LoadScriptFolder("mFramework2Test/Modules")
-- load Classes
Script.LoadScriptFolder("mFramework2Test/Classes")
```

Reload our mods main script, main.lua shouldnt do much of anything by default, setting up tables/vars is ok but keep most logic within methods
called by your Init() and Start() events.

```lua
-- reload our main script
Script.ReloadScript("mFramework2/main.lua")
```
_Note: we havent created main.lua yet, we'll do that later_

we need to create some callbacks to initialise and start our mod at the right times.
we do this using RegisterCallback(), we also want to ensure that our callbacks only run once.
we can use mFramework2's OnlyRunOnce wrapper for that, though it means we need an extra local for each callback

* First our `OnPreloaded` Callback, this is used to initialise out mods core files, loading or writing default config files etc, we shouldnt do any heavy work here.
  this callback is run after the core miscreated map and classes have loaded But before many of these systems have been properly initialised,
  you can make changes to core classes like player here and is when mFrameworks: CustomActions,CustomEntities,CustomPlayerEvents get reloaded and defined.

```lua
local OnPreLoaded = function()
    --- none of the base systems have loaded yet though in more advanced mods,
    --- we could use this space to check for existance  of needed files/folders.

    --- Run our Mods Init() method, we will pass the current cputime aswell,
    -- incase we want to use it for logging or calculating executiontimes etc
    g_mFramework2Test:Init(os.clock())
end
RegisterCallback(_G, 'OnInitPreLoaded', nil, function()
    --- this should only run once
    OnlyRunOnce(OnPreLoaded)
end)
```
_Note: we havent created our Init() method yet, we will do this in main.lua later_


* Next our `OnAllLoaded` Callback, here you can start you main mods logic eg spawning items in the world, interacting misdb data,
  interacting with online players and anything else realy, though you should remember callback order is not reliable. so other mods may not have finished starting yet,
  you should use other events/callbacks to handle dependancies or if you need some kind of communication with them
```lua
local OnAllLoaded = function()
    --- most of the base systems have loaded now though mFramework and other mods may still be starting,
    --- in more advanced mods, we could use this space to check for existance of other mods we are dependant on,
    --- and handling if they are missing but checking if other mods have loaded ok and such would need extra events/callbacks.

    --- Run our Mods Start() method. we will pass the current cputime aswell,
    -- incase we want to use it for logging or calculating executiontimes etc
    g_mFramework2Test:Start(os.clock())
end
RegisterCallback(_G, 'OnInitAllLoaded', nil, function()
    --- this should only run once
    OnlyRunOnce(OnAllLoaded)
end)
```
_Note: we havent created our Start() method yet, we will do this in main.lua later_


Thats it, you can add stuff here as needed, but this is the bare minimum needed to "initialise & start" your mod.
_though we still need to create that `main.lua` and everything else our mod does...._ <br>
Next up: [Example Mod: Main Script](./b2-ExampleMod-mod_main.md)