local DataStore = require("mFramework2.Classes.DataStore")
local fs = FS

--- cached playerdata, used to avoid needless writes to misdb
local playerCache = {}

---* ServerManager Player
---| `local smPlayer = g_ServerManager.Class.Player`
---| `local player = smPlayer(player)`
local smPlayer = Class {}

local function Init_PlayerData(PlayerData, player)
    --- Current Players Name
    ---@type string
    PlayerData:SetValue('playerName', player:GetName())

    --- Current players SteamId
    ---@type string
    PlayerData:SetValue('steamId', player.player:GetSteam64Id())

    --- Default `Player` ServerRank
    ---@type number
    PlayerData:SetValue('serverRank', 99)

    --- Default Permissions
    ---@type table
    local perms = {CHAT_CHANNELS_ACCESS = true, SERVER_KITS = true, SERVER_VOTES = true, PVE_AREAS = true}
    PlayerData:SetValue('permissions', perms)
    --- Last Known Player Location
    ---@type vector
    local location = player:GetPos()
    PlayerData:SetValue('location', location)

    --- Set Marker to avoid reinit
    PlayerData:SetValue('__Initialised__', true)
end

local player -- avoid player ref being accessable via class obj
function smPlayer:new(obj)
    player = obj -- avoid player ref being accessable via class obj
    if type(player) == 'number' then player = System.GetEntity(player) end
    if not (player and player['player']) then return nil end
    self.steamId = player.player:GetSteam64Id()
    self.PlayerData = DataStore {
        name = self.steamId,
        persistance_dir = fs.joinpath(g_ServerManager.BASEDIR, 'PlayerData/'),
    }
    local Initialised = self.PlayerData:GetValue('__Initialised__')
    if not Initialised then Init_PlayerData(self.PlayerData, player) end

    -- Init playerCache for Player
    playerCache[self.steamId] = {lastLocation = player:GetPos(), permissions = self.PlayerData:GetValue('permissions')}
end

function smPlayer:Location()
    local location = player:GetPos()
    if location ~= playerCache[self.steamId].lastLocation then self.PlayerData:SetValue('location', location) end
    return location
end

function smPlayer:Name()
    local name = player:GetName()
    self.PlayerData:SetValue('playerName', name)
    return name
end

function smPlayer:SetRank(rankId)
    if assert_arg(1, rankId, 'number') then return false, 'must pass a valid rankId' end
    self.PlayerData:SetValue('serverRank', rankId)
    return true
end

function smPlayer:GetRank()
    local playerRank = self.PlayerData:GetValue('serverRank')
    if (not type(playerRank) == 'number') and (playerRank >= 99) then
        return false, 'player does not have a valid rank'
    else
        return playerRank
    end
end

function smPlayer:SetPermission(permission, value)
    if assert_arg(1, permission, 'string') then
        return false, 'invalid permission name (must be string)'
    elseif assert_arg(2, value, 'number') then
        return false, 'can only set boolean true/false'
    end
    local permissions = self.PlayerData:GetValue('permissions')
    permissions[permission] = value
    if permissions ~= playerCache[self.steamId] then self.PlayerData:SetValue('permissions', permissions) end
end

function smPlayer:GetPermission(permission)
    if assert_arg(1, permission, 'string') then return false, 'invalid permission name (must be string)' end
    local permissions = self.PlayerData:GetValue('permissions')
    if permissions[permission] then return true, 'player has this permission' end
    return false, 'player does not have this permission'
end