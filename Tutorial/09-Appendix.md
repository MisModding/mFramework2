### mFramework Tutorial
## Appendix
----

    TODO: Finish Appendix


Common mFramework Stuff - a list of most used mFramework Methods/Modules and classes.
this isnt everything Offered by mFramework, rather a small list of the most commonly used features

- Common Methods:

```lua
--- run the provided function "f" only once.
---| (func gets stored in g_runOnceCache and if present will not run again)
---| important: this doesnt work with anonomous functions. pass a function as a variable
---@param f function    provided function to run Once
OnlyRunOnce(f)

--- run the provided function "f" Only on Server
---| only runs if CryAction.IsDedicatedServer() == true
---| allways runs if in Editor ie: System.IsEditor() == true
---@param f function    provided function to run on Server
ServerOnly(f)

--- run the provided function "f" Only on Client
---| only runs if CryAction.IsDedicatedServer() == false
---| allways runs if in Editor ie: System.IsEditor() == true
---@param f function    provided function to run on Client
ClientOnly(f)

--- register a module with the included custom Loader
---| libraries/modules inside pak files are not compatible with require()
---| this allows you to "register" a module and save it to global cache to load with require()
---| module path should be based around the relative path starting in GameSDK
---| so a module in "Scripts/mFramework/Modules/MyModule.lua" should be Registered as
---| "Scripts.mFramework.Modules.MyModule.lua"
---@param modulepath string     modulepath to register
---@param mod        table      module to register
RegisterModule(modulepath,mod)
```

----

- Common Modules:

    TODO: Include Common Modules Info

----

- Common Classes:

    TODO: Include Common Classes Info

----
