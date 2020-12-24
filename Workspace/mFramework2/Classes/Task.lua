local Task = {}

--- Create a task.
---@param name string the task name
---@param fn function the task method.
--- Note: your task method must return `false, result` while its running
--- and `true, result` when compleated.
function Task:new(name, fn)
    --- This tasks Name
    self.name = name
    --- Current Task Status [sleeping,running,finished,dead]
    self.status = "sleeping"
    --- is this Task enabled?
    self.enabled = false
    --- how many times this task ran since the last reset
    self.runCount = 0
    --- when this task was started (in CPU time)
    self.startTime = nil
    --- when this task finished (in CPU time)
    self.finishTime = nil
    --- Task main method
    self.thread = coroutine.wrap(function(...)
        local ranOk, compleated, result
        self.startTime = os.clock()
        while (not compleated) and (not self.enabled == false) do
            self.status = "running"
            ranOk, compleated, result = pcall(fn, ...)
            self.runCount = (self.runCount or 0) + 1
            if ranOk then
                if (not compleated) then
                    self.status = "waiting"
                    if result then self.result = result end
                    coroutine.yield(result)
                else
                    self.status = "finished"
                    if result then self.result = result end
                    self.finishTime = os.clock()
                    return result
                end
            else
                self.status = "dead"
                if result then self.result = result end
                return result
            end
        end
    end)
end

--- Enable this Task
function Task:enable() self.enabled = true end

--- Disable this Task
function Task:disable() self.enabled = false end

--- Reset this task (allows you to run a finished or dead task)
function Task:reset()
    self.enabled = false
    self.status = "sleeping"
    self.runCount = 0
    self.startTime = nil
    self.finishTime = nil
end
--- Run this Task
--- Any provided arguments will be passed to the tasks main method.
--- Note: you can only set these args once, subsequent calls to Task:run()
--- will use the same values as the first.
function Task:run(...)
    if (not self.enabled == true) then
        return false, "Task not enabled"
    elseif (self.status == "finished") then
        return false, "Task compleated"
    elseif (self.status == "dead") then
        return false, "Task Error"
    end
    self.thread(...)
end

return setmetatable(Task, {
    __call = function(self, ...)
        self:new(...)
        return self
    end
})
