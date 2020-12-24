if not g_mFramework then return end

local function isDebug()
    local dbg = false
    if (System.GetCVar('log_verbosity') == 3) then
        dbg = true
    elseif (g_mFramework.LOGLEVEL >= 3) then
        dbg = true
    end
    return dbg
end

local function init()
    local template = [[  [${level}:${prefix}] >> 
        ${content}"]]

    local logfile = {
        path = g_mFramework.LOGFILE,
        update = function(self, line)
            local file = io.open(self.path, 'a+')
            if file then
                file:write(line .. '\n')
                file:close()
                return true, 'updated'
            end
            return false, 'failed to update file: ', (self.path or 'invalid path')
        end,
        purge = function (self)
            os.remove(self.path)
        end
    }

    local function writer(logtype, source, message)
        local line = string.expand(template, {level = logtype, prefix = source, content = message})
        return logfile:update(os.date() .. '  >> ' .. line)
    end

    --- Writes a [Log] level entry to the mFramework log
    g_mFramework.Log = function(source, message)
        if not (g_mFramework.LOGLEVEL >= 1) then return end
        return writer('LOG', source, message)
    end

    --- Writes a [Error] level entry to the mFramework log
    g_mFramework.Err = function(source, message)
        if not (g_mFramework.LOGLEVEL >= 1) then return end
        return writer('ERROR', source, message)
    end

    --- Writes a [Warning] level entry to the mFramework log
    g_mFramework.Warn = function(source, message)
        if not (g_mFramework.LOGLEVEL >= 2) then return end
        return writer('WARNING', source, message)
    end
    --- Writes a [Debug] level entry to the mFramework log
    g_mFramework.Debug = function(source, message)
        if not isDebug() then return end
        return writer('DEBUG', source, message)
    end

    logfile:purge()
end

OnlyRunOnce(init)
