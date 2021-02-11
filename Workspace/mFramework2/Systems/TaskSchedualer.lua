local Task = require('mFramework2.Classes.Task')
local Timer = require('mFramework2.Classes.Timer')

---@class mTaskManager
---@field Properties table<string,string|number|boolean> `TaskManager Settings`
---@field tasks table<number,mTask> `tasks handled by this taskmanager instance`

---@type mTaskManager
local TaskManager = Class {
    Properties = {
        --- how often this task updates (milliseconds)
        updateRate = 1250,
        --- each update the total runtime of all tasks must not exceed this number (seconds)
        timeout = 1,
    },
}

--- Create new TaskManager
---@param   updateRate?     number      in millseconds:`how often to update (run) the task`
---@param   updateTimeout?  number      in seconds:`max runtime for each update`
function TaskManager:new(updateRate, updateTimeout)
    self.timer = Timer() ---@type mTimer
    self.timer:reset()
    if (type(updateRate) == 'number') then
        -- Override default update Rate
        self.Properties['updateRate'] = updateRate
    end
    if (type(updateTimeout) == 'number') then
        -- Override default update Timeout
        self.Properties['timeout'] = updateTimeout
    end
end

--- Sets the TaskManager Timout
--- the combined runtime of all tasks each update must not exceed this number (seconds)
function TaskManager:setTimeout(timeout)
    if assert_arg(1, timeout, 'string') then return false, 'invalid timout (must be a number)' end
    self.Properties['timeout'] = timeout
    return true
end

--- Sets the TaskManager Update Rate in milliseconds
---@param   milliseconds    number      milliseconds:`TaskManager Update Rate`
function TaskManager:setUpdateRate(milliseconds)
    if assert_arg(1, milliseconds, 'number') then return false, 'invalid timout (must be a number)' end
    self.Properties['timeout'] = milliseconds
    return true
end

function TaskManager:createTask(name, method)
    local task = FindInTable(self.tasks, 'name', name)
    local t_data = {name = name}
    if task then
        return false, 'task exists'
    else
        task = Task(name, method) ---@type mTask
        if task and (task.status == 'sleeping') then
            InsertIntoTable(self.tasks, task)
            return true, string.expand('succesfully created task: ${name}', t_data)
        else
            return false, string.expand('failed to create task: ${name}', t_data)
        end
    end
end

function TaskManager:deleteTask(name)
    local task = FindInTable(self.tasks, 'name', name)
    local t_data = {name = name}
    if (not task) then
        return false, string.expand('unknown task: ${name}', t_data)
    else
        RemoveFromTable(self.tasks, task)
        return true, string.expand('task removed: ${name}', t_data)
    end
end

function TaskManager:enableTask(name)
    local task = FindInTable(self.tasks, 'name', name) ---@type mTask
    local t_data = {name = name}

    if not task then
        return false, string.expand('unknown task: ${name}', t_data)
    else
        local enabled
        enabled, t_data['status'] = task:enable()
        if not enabled then
            -- t_data.status contains any returned message
            return false, string.expand('failed to enable task: ${name}, ${status}', t_data)
        end
        return true, string.expand('succesfully enabled task: ${name}', t_data)
    end
end

function TaskManager:disableTask(name)
    local task = FindInTable(self.tasks, 'name', name) ---@type mTask
    local t_data = {name = name}

    if not task then
        return false, string.expand('unknown task: ${name}', t_data)
    else
        local disabled
        disabled, t_data['status'] = task:disable()
        if not disabled then
            -- t_data.status contains any returned message
            return false, string.expand('failed to disable task: ${name}, ${status}', t_data)
        end
        return true, string.expand('succesfully disabled task: ${name}', t_data)
    end
end

function TaskManager:Start() self.timer:start() end

local updateThread = function(self)
    local updateRate = self.Properties['updateRate']
    mFramework2.Debug('TaskManager:thread', string.expand('Shedualing Task Update in ${rate}ms', {rate = updateRate}))
    Script.SetTimerForFunction(updateRate, self['Update'], self)
end

function TaskManager:Update()
    local timer = self.timer
    local timeout = self.Properties['timeout']
    local startTime = timer:stats().runtime

    ---@type mTask
    for index, task in ipairs(self.tasks) do
        -- track runtime
        local runtime = (timer:stats().runtime - startTime)

        -- check timeout
        if (not runtime >= timeout) then
            task.task_index = index
            -- check task is runnable
            if (task.status == 'dead') then
                mFramework2.Debug('TaskManager', string.expand('${task_index}> Cannot run Dead task: ${name}', task))
            elseif (task.status == 'finished') then
                mFramework2.Debug('TaskManager', string.expand('${task_index}> Cannot run finished task: ${name}', task))
            end
        else
            local err = '${task_index}> Timout: TaskManager:Update()....! task: ${name} run_time:${time}s'
            local errVal = {name = task.name, runtime = tostring(runtime), timeout = tostring(timeout)}
            mFramework2.Debug('TaskManager', err:expand(errVal))
            return false, 'Tinout'
        end
    end
    updateThread(self)
end
