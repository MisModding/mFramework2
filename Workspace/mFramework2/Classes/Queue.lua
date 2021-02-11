local Queue = {}
local meta = {__index = Queue, __call = function(self, ...) return self:new(...) end}

function Queue.new(self) return self end

--- add a value to the queue stack
---@param value? any
function Queue.push(self, value)
    if (self.back == nil) or self:empty() then
        self.back = 1
        self.front = 1
        self.array = {}
    end
    self.array[self.back] = value
    self.back = self.back + 1
end

--- pop a value off the queue stack
function Queue.pop(self)
    if self.front == self.back then return nil end
    local value = self.array[self.front]
    self.array[self.front] = nil
    self.front = self.front + 1
    return value
end

--- peek at the queue stack
---@param level? number `stack level to peek at`
function Queue.peek(self, level)
    if self.front == self.back then return nil end
    local value = self.array[self.front + (level or 0)]
    return value
end

--- empty the queue stack
function Queue.empty(self) return self.front == self.back end

--- returns the size of the queue stack
function Queue.size(self) return self.back and self.back - self.front or 0 end

--- compleatly reset this queue
function Queue.purge(self)
    self.array = nil
    self.back = nil
    self.front = nil
end

local exports = setmetatable({}, meta)

RegisterModule('mFramework2.Classes.Queue', exports)
return exports
