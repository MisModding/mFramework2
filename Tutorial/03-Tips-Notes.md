### mFramework Tips
## Tips and things to Note
----

[Home](/mFramework2)

* Folder Structure:
    - at runtime all main mFramework resources can be found in the `./mFramework2/` folder outside of the usual `./Scripts/` path.
        - an exception to this is a few modding targeted files/folders namely: 
            - `./Scripts/mFramework2/CustomEntities`for CutomEntity Definitions.
            - `./Scripts/mFramework2/CustomActions`for CustomAction Definitions.
            - `./Scripts/mods/mFramework.lua` file used to bootstrap the framework at start time.
        - you should not add or modify files within the `./mFramework2/` path, use `./Scripts/mFramework2/`
    - MisDB files are found in the `./MisDB/` folder outside of the usual `./Scripts/` path
        - you should not add or modify files within `./MisDB`

* Load Order:

    Load Order is important to Know and doing things at certain times can be usefull or in some cases needed for certain things to function
    Miscreated provides a few methods to handle doing things at the right times while everything is loading:
    - OnInitPreLoaded()
        this method gets called when all the core map and lua classes / code
    - OnInitAllLoaded()


    mFramework uses RegisterCallback() to attach itself to miscreated's `OnInitPreloaded()`/`OnInitAllLoaded()` events.

    this works great most of the time but seems to become a little unreliable with timing when many mods all register callbacks on these methods.
    
    to ensure that you load after mFramework has Fully initialised you can make use of mFrameworks event system.
    ```lua
    local events = mFramework2.Events

    -- create a callback to observe mFrameworks OnPreLoaded event
    events:observe('mFramework2:OnPreLoaded',function(cTime)
        --- Call your mods OnPreLoaded Method here cTime contains the os.date() when mFramework finished PreLoading
    end)

    -- create a callback to observe mFrameworks OnAllLoaded event
    events:observe('mFramework2:OnPreLoaded',function(cTime)
        --- Call your mods OnAllLoaded Method here cTime contains the os.date() when mFramework finished Loading
    end)
    ```
    _Events are used in Various places throughout mFramework and can be usefull to react to certain things or pass data between mods via emitters and observers_
