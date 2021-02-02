--
-- ────────────────────────────────────────────────────────────────────────────────────────── I ──────────
--   :::::: S V A L T E K   C O N F I G S T O R E   C L A S S : :  :   :    :     :        :          :
-- ────────────────────────────────────────────────────────────────────────────────────────────────────
-- vscode-fold=3

-- @classmod DataStore
--
-- ─── TYPES ──────────────────────────────────────────────────────────────────────
--
---@class ConfigStore_Options
---@field name string Name of This DataStore | will be used as MisDB FileName.
---@field persistance_dir string Path where to store this ConfigStores data.
--
-- ──────────────────────────────────────────────────────── CONFIGSTORE CLASS ─────
--
---@class DataStore
---@field DataSource table
---@field new fun(self:DataStore,config:ConfigStore_Options|nil):DataStore
local DataStore = Class {}
---* Defines a MisDB Backed Key/Value storage

---* DataStore(config)
-- Create a New DataStore
---@param config table Config
---@usage
--      local MyClass = Class {}
--      function MyClass:new()
--          local configstore = {name = 'ConfigStoreName', persistance_dir = 'dataDir'}
--          self:implement(g_ServerManagerClass.DataStore)
--      end
function DataStore:new(config)
    if assert_arg(1, config, 'table') then return nil end
    if not config['persistance_dir'] then
        return nil, 'must specify persistance_dir'
    elseif not config['name'] then
        return nil, 'must specify a name'
    end
    self.DataSource = {
        Source = MisDB(config.persistance_dir), ---@type MisDB2
    }
    self.DataSource['Data'] = self.DataSource['Source']:Collection(config.name) ---@type MisDB2_Collection
    return self
end
---* Fetches a Value from this DataStore
---@param key string ConfigKey
---@return number|string|table|boolean ConfigValue
function DataStore:GetValue(key)
    local Cache = (self.DataSource['Data'] or {})
    return Cache[key]
end
---* Saves a Value to this DataStore
---@param key string ConfigKey
---@param value number|string|table|boolean Value
---@return boolean Successfull
function DataStore:SetValue(key, value)
    local Cache = (self.DataSource['Data'] or {})
    Cache[key] = value
    res = self.DataSource.Data:save("Data")
    return res
end
--
-- ─── EXPORTS ────────────────────────────────────────────────────────────────────
--
RegisterModule('mFramework2.Classes.DataStore',DataStore)
g_mFramework.Classes.DataStore = DataStore
return DataStore