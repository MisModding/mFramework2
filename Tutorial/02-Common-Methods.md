### mFramework Tutorial
## Common Methods
----

[Home](/mFramework2)

mFramework Common Methods Tutorial

    TODO: Write Common Methods Tutorial


```lua

--- ServerOnly: Fetch a random player from a list (by default it uses CryAction.GetPlayerList to fetch all online players)
---@param list table<number,player> table of players to choose from eg: `local chosenPlayer = GetRandomPlayer(CryAction.GetPlayerList())`
GetRandomPlayer(list) ---@return player chosen

--- recursive read-only definition, use this to mark all feilds in a table as readonly. attempts to change values in a readonly table will result in an error
--- this function returns a proxyTable that makes use of metatables to handle accesses to the source table
--- example:
--- local myConfigTable = {version = "1.0.3", mod_id = 23214324}
--- myMod.Config = readOnly(myConfigTable) -- assign our readonly proxytable, all keys inside our source table are now protected readonly.
--- values can only be changed via rawset or via the original table reference
---@param t table the source table to protect
readOnly(t) ---@return proxyTable object to access the protected table


--- Used for patching CVars at runtime.
--- given a key=value list of CVars to update this method will run through each patching those that need changing
--- eg: PatchVars { ['log_Verbosity'] = 3, ['log_WriteToFileVerbosity'] = 3 }
---@param vars table of CVars to update
PatchVars( vars )

--- run the provided function "f" only once.
-- (func gets stored in g_runOnceCache and if present will not run again)
-- important: this doesnt work with anonomous functions. pass a function as a variable
---@param f function    provided function to run Once
OnlyRunOnce(f)

--- run the provided function "f" Only on Server
-- only runs if CryAction.IsDedicatedServer() == true
-- allways runs if in Editor ie: System.IsEditor() == true
---@param f function    provided function to run on Server
ServerOnly(f)

--- run the provided function "f" Only on Client
-- only runs if CryAction.IsDedicatedServer() == false
-- allways runs if in Editor ie: System.IsEditor() == true
---@param f function    provided function to run on Client
ClientOnly(f)

--- register a module with the included custom Loader
-- libraries/modules inside pak files are not compatible with require()
-- this allows you to "register" a module and save it to global cache to load with require()
-- module path should be based around the relative path starting in GameSDK
-- so a module in "Scripts/mFramework/Modules/MyModule.lua"
-- should be Registered as "mFramework.Modules.MyModule"
---@param modulepath string     modulepath to register
---@param mod        table      module to register
RegisterModule(modulepath,mod)
```
