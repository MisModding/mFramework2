-- Create a new Class
local Classy = {}

Classy.KnownClasses = {}
function Classy:Create(name, base)
    -- empty class Object
    local Object
    Object = {
        __index = {
            Extend = function(self)
                local obj = {super = self}
                return setmetatable(obj, Object)
            end,
        },
        __type = 'Object',
        __tostring = function(this) return getmetatable(this).__type end,
        __call = function(this, ...)
            local obj = setmetatable({}, {__index = this})
            if this['super'] and this.super['new'] then this.super.new(obj, ...) end
            if this['new'] then this.new(obj, ...) end
            return obj
        end,
    }
    -- handle named classes
    if name then
        -- if the class exists, return it.
        if self.KnownClasses[name] then
            return self.KnownClasses[name]
        else
            -- set the Object type
            Object.__type = name

            local obj = {}
            -- populate class definition
            if (type(base) == 'table') then for k, v in pairs(base) do obj[k] = v end end
            setmetatable(obj, Object)
            self.KnownClasses[name] = obj
            return obj
        end
    else
        -- just return a new object
        return setmetatable({}, Object)
    end
end

local meta = {__call = function(self, ...) return self:Create(...) end}

Class = setmetatable(Classy, meta)
