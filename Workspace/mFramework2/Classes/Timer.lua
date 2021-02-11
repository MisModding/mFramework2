--
-- ──────────────────────────────────────────────────────────────────────────────────────────── I ──────────
--   :::::: S V A L T E K   S I M P L E   T I M E R   C L A S S : :  :   :    :     :        :          :
-- ──────────────────────────────────────────────────────────────────────────────────────────────────────
local timer

-- Dependancies

--- Used internally to update timer stats
local function timer_update(t)
    if not t.timer_active then return end
    local timeNow = os.time()
    t.runtime = timeNow - t.started
    t.lifetime = timeNow - t.created
end

--
-- ────────────────────────────────────────────────────────────── SIMPLETIMER ─────
--

---@class mTimer
---@field state table `Timer state`
---* Simple Timer Class
timer = Class {
    --- used to store this timers state
    state = {},
}

---*Create a new Timer
--- optionaly: provide the epoch to continue an existing timer.
function timer:new(epoch)
    self.state['created'] = (epoch or os.time())
    return self
end

---* Start this timer
--- returns true or false if timer is allready running
--- and the epoch start time
function timer:start()
    --- grab start time asap
    local started = os.time()
    if (self.state['timer_active'] ~= true) then
        self.state['timer_active'] = true
        self.state['started'] = started
        timer_update(self.state)
        return true, started
    end
    return false
end

---* Stop this timer
--- returns true or false if timer is allready stopped
function timer:stop()
    --- grab stop time asap
    local stopped = os.time()
    if (self.state['timer_active'] ~= false) then
        timer_update(self.state)
        self.state['timer_active'] = false
        self.state['stopped'] = stopped
        return true, stopped
    end
    return false
end

---* Resets this timers runtime, does NOT reset the lifetime or creation stats.
function timer:reset()
    timer_update(self.state)
    local reset = os.time()
    self.state['reset'] = reset
    self.state['runtime'] = 0
    self.state['lastreset'] = os.time()
    return true, reset
end

---* fetch this timers stats.
function timer:stats()
    timer_update(self.state)
    return {
        created = self.state['created'],
        started = self.state['started'],
        stopped = self.state['stopped'],
        runtime = self.state['runtime'],
        lifetime = self.state['lifetime'],
    }
end

RegisterModule('mFramework2.Classes.Timer', timer)
return timer