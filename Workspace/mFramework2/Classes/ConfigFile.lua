local configReader = require('mFramework2.Modules.configReader')

---@class ConfigFile
---@field Options table<string,string|number|boolean>
local ConfigFile = Class {__type = 'ConfigFile', Options = {FILE_PATH = nil, PROTECT = true}}

function ConfigFile:new(path, options)
    if assert_arg(1, 'path', 'string') then return false, 'invalid path (must be a string)' end
    if type(options) == table then for key, value in pairs(options) do self.Options[key] = value end end
    self.Options['FILE_PATH'] = path
    self:reload()
end

function ConfigFile:reload()
    local filepath = self.Options['FILE_PATH']
    local config = configReader.read()
    if not config then return false, string.expand('failed to read file ${file}', {filepath = filepath}) end
    self.Config = nil
    if self.Options['PROTECT'] then
        self.Config = readOnly(config)
    else
        self.Config = config
    end
end

RegisterModule('mFramework2.Classes.ConfigFile', ConfigFile)
return ConfigFile
