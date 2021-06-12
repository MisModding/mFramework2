-- >> just incase this file gets reloaded multiple times, lets not wipe out any existing cached modules
if not g_mCustomModules then g_mCustomModules = {} end
--
-- ─── CUSTOMLOADER ───────────────────────────────────────────────────────────────
--

--- Internal: loadLuaMod(modulename)
---| Loads the Specified Module by namespace , if found in _G["g_mCustomModules"]
---@param modulename string     module namespace
---@return table|string         either a table returned by this module or a string for error
local function loadLuaMod(modulename)
    local errmsg = 'Failed to Find Module'
    -- Find the Module.
    local LuaMods = _G['g_mCustomModules']
    local this_module = LuaMods[modulename]
    -- basic validation.
    if (type(this_module) == 'function') then
        -- basic test for errors.
        local testOk, testResult = pcall(this_module)
        if testOk then
            return this_module
        else
            return testResult
        end
    end
    return errmsg
end
-- Install the loader so that it's called just before the normal Lua loader
table.insert(package.loaders, 2, loadLuaMod)

-- [Usable Methods]
-- ────────────────────────────────────────────────────────────────────────────────

---* Registers a Module Table with the Custom Loader
--- returns boolean and a message on error
---@param name string Module Name
-- This is the Module Name used to Load the Registered Module, you should follow require standards.
-- thus a module found in Scripts/MyMod/MyModule.lua should be named "Scripts.MyMod.MyModule"
---@param this_module table Module Table
-- This table Defines your Module, same as you would return in a standard module,
---@return boolean success
---@return string errorMsg
function RegisterModule(name, this_module)
    if (type(name) ~= 'string') or (name == ('' or ' ')) then
        return false, 'Invalid Name Passed to RegisterModule, (must be a string and not empty).'
    elseif (type(this_module) ~= 'table') or (this_module == {}) then
        return false, 'Invalid Module Passed to RegisterModule, (must be a table and not empty).'
    end
    local CustomModules = _G['g_mCustomModules']

    -- Wrap the module in a function for the loader to return.
    local ModWrap = function()
        local M = this_module
        return M
    end

    -- Ensure this Module doesnt allready Exist
    if CustomModules[name] then
        return false, 'A Module allready Exists with this Name.'
    else -- all ok, attempt to push the module into package.loaded
        CustomModules[name] = ModWrap
    end

    if (CustomModules[name] == ModWrap) then -- named package matches module.
        return true, 'Module ' .. name .. ' Loaded succesfully'
    else -- somehow named package doesnt match our module, something bad happened.
        return false, 'Something went Wrong, the Loaded module didnt match as Expected.'
    end

    return nil, 'Unknown Error' -- This should never happen.
end
