local function isSteam64Id(query)
    if type(query) ~= "string" then
        return false, "must be a string"
    end
    if (not string.len(query:gsub("%s","")) == "17") then
        return false, "string must be 17 characters"
    else
        local i = 1
        for c in string.gmatch(query, ".") do
            if (not type(tonumber(c)) == "number") then
                return false, "failed to cast char: " .. tostring(i) .. " to number"
            end
            i = i + 1
        end
        return true, "appears to be a steam id"
    end
end

--- find a player by name or steamId, supports partial matches
---| Case Sensitive,  ALLWAYS Verify correct player found.
---@param query string
---@return entity|nil
---@return string errormsg
function FindPlayer(query)
    local players, player, result
    if (type(query) == "string") then
        local steam64Id = isSteam64Id(query)
        players = System.GetEntitiesByClass("Player")
        for i, ent in ipairs(players) do
            if (not steam64Id) then
                if string.find(ent:GetName(), query, nil, true) then
                    player = ent
                else
                    result = "Player with name: " .. query .. " Not found"
                end
            else
                if string.find(ent.player:GetSteam64Id(),query,nil,true) then
                    player = ent
                else
                    result = "Player with SteamId: " .. query .. " Not found"
                end
            end
        end
    end
    return player, (result or 'Invalid Query. Must be a string')
end

function GetEntityInfo(ent)
    if (not ent) then return nil end
    local this_entity = System.GetEntity(ent)
    if (not this_entity) then return nil, 'Entity Not Found' end
    local ent_name = (this_entity:GetName() or 'Unknown')
    local ent_class = (this_entity.class or 'Unknown')
    local ent_id = tostring(this_entity.id)
    return '[Entity]> Name: ' .. ent_name .. ' { Class = ' .. ent_class ..
               ' EntityID = ' .. ent_id .. ' }'
end