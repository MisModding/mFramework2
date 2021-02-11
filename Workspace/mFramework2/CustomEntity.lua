--- @author Theros   ~ Discord: Theros#7648, Site: https://svaltek.xyz.
-- Provides Methods used for Custom Entity/Action Support.
if not g_mReExposeIndex then g_mReExposeIndex = {} end

function ReExposeAllRegistered()
    for k, v in pairs(g_mReExposeIndex) do
        mFramework2.Log('CustomEntity', 'ReExposing: ' .. tostring(k))
        _G[k] = mergef(_G[k], v.methods, true)
        ---Expose
        local e = v.expose
        Net.Expose {
            Class = _G[k],
            ServerProperties = e.ServerProperties,
            ServerMethods = e.ServerMethods,
            ClientMethods = e.ClientMethods,
        }
    end
end

local function RegisterForReExpose(exposeData)
    -- ReExpose Data
    local classToExpose = exposeData['class']
    local thisEntity = new(_G[classToExpose])

    -- Fetch any existing cached ReExpose for this class and merge
    local ReExposeCache = (g_mReExposeIndex[classToExpose] or {methods = {}, expose = {}})
    thisEntry = {
        methods = mergef(ReExposeCache.methods, exposeData['methods'], true),
        expose = mergef(ReExposeCache.expose, exposeData['expose'], true),
    }
    local cls = mergef(thisEntity, thisEntry, true)
    if cls then
        g_mReExposeIndex[classToExpose] = cls
        mFramework2.Log('CustomEntity', string.format('Class: %s registered for ReExpose.', tostring(classToExpose)))
        return true, 'Registered'
    end
    return false, 'failed to register'
end

--- mReExpose: Merges new Methods and ReExposes the Provided Class
---@param c string   Class to ReExpose
---@param m table   Your Method Table
---@param e table   Your Expose Table
function mReExpose(c, m, e)
    if (not type(c) == 'string') or (not _G[c]) then
        return nil, 'Invalid Class or None provided'
    elseif (not type(m) == 'table') then
        return nil, 'Invalid Method table or None Provided'
    elseif (not type(e) == 'table') then
        return nil, 'Invalid Expose table or None Provided'
    else
        if (not e.ServerMethods) then
            return nil, 'Your Expose Table MUST Contain the ServerMethods table'
        elseif (not e.ClientMethods) then
            return nil, 'Your Expose Table MUST Contain the ClientMethods table'
        elseif (not e.ServerProperties) then
            return nil, 'Your Expose Table MUST Contain the ServerProperties table'
        else
            return RegisterForReExpose {class = c, methods = m, expose = e}
        end
    end
end

