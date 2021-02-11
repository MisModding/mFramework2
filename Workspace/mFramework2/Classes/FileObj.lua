--- Create a empty table for our file Object
local fileObj

function fileObj:new(file_path) self.path = file_path end

function fileObj:load()
    local file = io.open(self.path, 'a+')
    if file then
        local result = file:read('*a')
        file:close()
        return result, 'success reading from file'
    end
    return false, 'failed read file: ', (self.path or 'invalid path')
end
--- update the ondisk copy
function fileObj:update(content)
    local file = io.open(self.path, 'a+')
    if file then
        file:write(content)
        file:close()
        return true, 'updated'
    end
    return false, 'failed to update file: ', (self.path or 'invalid path')
end
--- allow for deletion of the on disk copy
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
