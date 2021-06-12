---@class mFramework2.Classes.fileObj
---@field content string
local fileObj = {}

function fileObj:new(file_path) self.path = file_path end

function fileObj:load()
    local file = io.open(self.path, 'a+')
    if file then
        self.content = file:read('*a')
        file:close()
        return self.content, 'success reading from file'
    end
    return false, 'failed read file: ', (self.path or 'invalid path')
end

--- update the ondisk copy
---@param content any
---@return boolean
---@return string
---@return string
function fileObj:update(content)
    local file = io.open(self.path, 'a+')
    --fallback to cached if no data passed
    if (not content) then content = self.content end

    if file then
        file:write(content)
        file:close()
        self.content = content
        return true, 'updated'
    end
    return false, 'failed to update file: '.. (self.path or 'invalid path')
end

--- deletion of on disk copy
function fileObj:purge() os.remove(self.path) end


setmetatable(fileObj, {
    --- make this Object Callable
    __call = function(self, ...)
        self:new()
        return self
    end,
})

RegisterModule('mFramework2.Classes.fileObj', fileObj)
return fileObj
