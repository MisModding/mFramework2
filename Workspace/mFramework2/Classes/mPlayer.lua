local MisDB = require( 'MisDB' )
local DataStore = MisDB.DataStore
local fs = FS

---helper for grabing a date as a table
function getDate( epoch ) return os.date( '*t', epoch ) end

---* mFramework2 Player Class
---@class mFramework.Player
local Player = Class( 'mFramework2.Classes.Player', {} )

--- default player permissions
local default_perms = {IS_OWNER = false, IS_VIP = false, IS_GUEST = true}

local default_player_meta = {firstJoined = getDate(os.time())}

---internal initialise playerData
---@param PlayerData MisDB.DataStore
---@param player player
local function Init_PlayerData( PlayerData, player )
    --- Current Players Name
    ---@type string
    PlayerData:SetValue( 'playerName', player:GetName() )

    --- Current players SteamId
    ---@type string
    PlayerData:SetValue( 'steamId', player.player:GetSteam64Id() )

    --- Default Permissions
    ---@type table
    PlayerData:SetValue( 'permissions', default_perms )
    --- Last Known Player Location
    ---@type vector
    local location = player:GetPos()
    PlayerData:SetValue( 'location', location )

    --- init player Meta
    PlayerData:SetValue( 'playerMeta', default_player_meta )

    --- Set Marker to avoid reinit
    PlayerData:SetValue( '__Initialised__', true )
end

local function Update_PlayerData(self,player)
    if (not self.meta['online']) then
        --- update playerMeta
        local lastJoined = getDate(os.time())
        self:SetMeta( 'lastJoined', lastJoined)

        self.meta['online'] = true
    end
end



function Player:new( player )
    ---@type mFramework.CustomPlayer
    ---HACK: accept a entityId in the form of a number (eg in ce3 editor player has entityId:30583)
    if type( player ) == 'number' then player = System.GetEntity( player ) end
    if not (player and player['player']) then return nil end
    self.steamId = player.player:GetSteam64Id()
    ---@type MisDB.DataStore
    self.PlayerData = DataStore {name = self.steamId, persistance_dir = 'PlayerData/'}
    local Initialised = self.PlayerData:GetValue( '__Initialised__' )
    if not Initialised then Init_PlayerData( self.PlayerData, player ) end
    self.meta = self.PlayerData:GetValue( 'playerMeta' )
    Update_PlayerData(self,player)
    self.player = player ---@type CE3.player
end

function Player:Location()
    local location = player:GetPos()
    self.PlayerData:SetValue( 'location', location )
    return location
end

function Player:Name()
    local name = player:GetName()
    self.PlayerData:SetValue( 'playerName', name )
    return name
end

function Player:SetPermission( permission, value )
    if assert_arg( 1, permission, 'string' ) then
        return false, 'invalid permission name (must be string)'
    elseif assert_arg( 2, value, 'boolean' ) then
        return false, 'can only set boolean true/false'
    end
    local permissions = self.PlayerData:GetValue( 'permissions' )
    permissions[permission] = value
    return self.PlayerData:SetValue( 'permissions', permissions )
end

function Player:GetPermission( permission )
    if assert_arg( 1, permission, 'string' ) then
        return false, 'invalid permission name (must be string)'
    end
    local permissions = self.PlayerData:GetValue( 'permissions' )
    if permissions[permission] then return true, 'player has this permission' end
    return false, 'player does not have this permission'
end

function Player:GetMeta( key )
    if assert_arg( 1, key, 'string' ) then return false, 'invalid meta name (must be string)' end
    local meta_val = self.PlayerData:GetValue( 'playerMeta' )
    if meta_val[key] then return meta_val[key] end
end

function Player:SetMeta( key, value )
    if assert_arg( 1, key, 'string' ) then return false, 'invalid meta name (must be string)' end
    local meta_val = self.PlayerData:GetValue( 'playerMeta' )
    meta_val[key] = value
    self.meta[key] = value
    return self.PlayerData:SetValue( 'playerMeta', meta_val )
end

RegisterModule( 'mFramework2.Classes.Player', Player )
return Player
