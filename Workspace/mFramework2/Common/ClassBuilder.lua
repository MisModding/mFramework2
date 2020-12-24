-- Create a new Class
---| uses the classic.lua Object library
---@param base table optional class schema
function Class(base)
	---@class Object
	local Object = base or {}
	Object.__index = Object
	function Object:__tostring() return 'Object' end
	function Object:__call(...)
		local obj = setmetatable({}, self)
		obj:new(...)
		return obj
	end

	--- Create a new Instance of this Object.
	function Object:new() end
    --- Extend this Object.
    ---@return Object
	function Object:extend()
		local cls = {}
		for k, v in pairs(self) do
			if k:find("__") == 1 then
				cls[k] = v
			end
		end
		cls.__index = cls
		cls.super = self
		setmetatable(cls, self)
		return cls
	end
	--- Implement Methods from anouther Object.
	function Object:implement(...)
		for _, cls in pairs({...}) do
			for k, v in pairs(cls) do if self[k] == nil and type(v) == 'function' then self[k] = v end end
		end
	end
	--- Check an Objects type.
	function Object:is(T)
		local mt = getmetatable(self)
		while mt do
			if mt == T then return true end
			mt = getmetatable(mt)
		end
		return false
	end
	return Object:extend()
end