local Queue = {}
local meta = {
	__index = Queue,
	__call = function(self,...)
		return self:new(...)
	end
}

function Queue.new( self )
	return self
end

function Queue.push( self, value )
	if (self.back == nil) or self:empty() then
		self.back = 1
		self.front = 1
		self.array = {}
	end
	self.array[self.back] = value
	self.back = self.back + 1
end

function Queue.pop( self )
	if self.front == self.back then
		return nil
	end
	local value = self.array[self.front]
	self.array[self.front] = nil
	self.front = self.front + 1
	return value
end

function Queue.peek( self ,level)
	if self.front == self.back then
		return nil
	end
	local value = self.array[self.front + (level or 0)]
	return value
end

function Queue.empty( self )
	return self.front == self.back
end

function Queue.size( self )
	return self.back and self.back - self.front or 0
end

function Queue.purge( self )
	self.array = nil
	self.back = nil
	self.front = nil
end

local exports = setmetatable({}, meta)

RegisterModule("mFramework.Classes.Queue",exports)
return exports