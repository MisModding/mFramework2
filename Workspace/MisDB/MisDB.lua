local pathseparator = package.config:sub( 1, 1 );
function getPath( ... )
    local parts = {...}
    -- TODO: might be more useful to handle empty/missing parts
    if #parts < 2 then error( 'joinpath requires at least 2 parts', 2 ) end
    local r = parts[1]
    for i = 2, #parts do
        local v = string.gsub( parts[i], '^[' .. pathseparator .. ']', '' )
        if not string.match( r, '[' .. pathseparator .. ']$' ) then r = r .. '/' end
        r = r .. v
    end
    return r
end
local function isFile( path )
    local f = io.open( path, 'r' )
    if f then
        f:close()
        return true
    end
    return false
end
local function isDir( path )
    path = string.gsub( path .. '/', '//', '/' )
    local ok, err, code = os.rename( path, path )
    if ok or code == 13 then return true end
    return false
end
local function mkDir( path )
    local ok, Result = os.execute( 'mkdir ' .. path:gsub( '/', '\\' ) )
    if not ok then
        return nil, 'Failed to Create ' .. path .. ' Directory! - ' .. Result
    else
        return true, 'Successfully Created ' .. path .. ' Directory!'
    end
end

local function Callable( Object )
    return setmetatable( {}, {
        __index = Object,
        __call = function( self, ... )
            local ok, result
            if self['new'] then
                ok, result = self:new( ... )
                if (ok == false) then return false, result end
            end
            return self, result
        end,
    } )
end

local json = {}

-- Internal functions.

local function kind_of( obj )
    if type( obj ) ~= 'table' then return type( obj ) end
    local i = 1
    for _ in pairs( obj ) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return 'table'
        end
    end
    if i == 1 then
        return 'table'
    else
        return 'array'
    end
end

local function escape_str( s )
    local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
    for i, c in ipairs( in_char ) do s = s:gsub( c, '\\' .. out_char[i] ) end
    return s
end

-- Returns pos, did_find; there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
-- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
local function skip_delim( str, pos, delim, err_if_missing )
    pos = pos + #str:match( '^%s*', pos )
    if str:sub( pos, pos ) ~= delim then
        if err_if_missing then error( 'Expected ' .. delim .. ' near position ' .. pos ) end
        return pos, false
    end
    return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos; the returned pos is after the closing quote character.
local function parse_str_val( str, pos, val )
    val = val or ''
    local early_end_error = 'End of input found while parsing string.'
    if pos > #str then error( early_end_error ) end
    local c = str:sub( pos, pos )
    if c == '"' then return val, pos + 1 end
    if c ~= '\\' then return parse_str_val( str, pos + 1, val .. c ) end
    -- We must have a \ character.
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub( pos + 1, pos + 1 )
    if not nextc then error( early_end_error ) end
    return parse_str_val( str, pos + 2, val .. (esc_map[nextc] or nextc) )
end

-- Returns val, pos; the returned pos is after the number's final character.
local function parse_num_val( str, pos )
    local num_str = str:match( '^-?%d+%.?%d*[eE]?[+-]?%d*', pos )
    local val = tonumber( num_str )
    if not val then error( 'Error parsing number at position ' .. pos .. '.' ) end
    return val, pos + #num_str
end

-- Public values and functions.

function json.stringify( obj, as_key )
    local s = {} -- We'll build the string as an array of strings to be concatenated.
    local kind = kind_of( obj ) -- This is 'array' if it's an array or type(obj) otherwise.
    if kind == 'array' then
        if as_key then error( 'Can\'t encode array as key.' ) end
        s[#s + 1] = '['
        for i, val in ipairs( obj ) do
            if i > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify( val )
        end
        s[#s + 1] = ']'
    elseif kind == 'table' then
        if as_key then error( 'Can\'t encode table as key.' ) end
        s[#s + 1] = '{'
        for k, v in pairs( obj ) do
            if #s > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify( k, true )
            s[#s + 1] = ':'
            s[#s + 1] = json.stringify( v )
        end
        s[#s + 1] = '}'
    elseif kind == 'string' then
        return '"' .. escape_str( obj ) .. '"'
    elseif kind == 'number' then
        if as_key then return '"' .. tostring( obj ) .. '"' end
        return tostring( obj )
    elseif kind == 'boolean' then
        return tostring( obj )
    elseif kind == 'nil' then
        return 'null'
    else
        error( 'Unjsonifiable type: ' .. kind .. '.' )
    end
    return table.concat( s )
end

json.null = {} -- This is a one-off table to represent the null value.

function json.parse( str, pos, end_delim )
    pos = pos or 1
    if pos > #str then error( 'Reached unexpected end of input.' ) end
    local pos = pos + #str:match( '^%s*', pos ) -- Skip whitespace.
    local first = str:sub( pos, pos )
    if first == '{' then -- Parse an object.
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
            key, pos = json.parse( str, pos, '}' )
            if key == nil then return obj, pos end
            if not delim_found then error( 'Comma missing between object items.' ) end
            pos = skip_delim( str, pos, ':', true ) -- true -> error if missing.
            obj[key], pos = json.parse( str, pos )
            pos, delim_found = skip_delim( str, pos, ',' )
        end
    elseif first == '[' then -- Parse an array.
        local arr, val, delim_found = {}, true, true
        pos = pos + 1
        while true do
            val, pos = json.parse( str, pos, ']' )
            if val == nil then return arr, pos end
            if not delim_found then error( 'Comma missing between array items.' ) end
            arr[#arr + 1] = val
            pos, delim_found = skip_delim( str, pos, ',' )
        end
    elseif first == '"' then -- Parse a string.
        return parse_str_val( str, pos + 1 )
    elseif first == '-' or first:match( '%d' ) then -- Parse a number.
        return parse_num_val( str, pos )
    elseif first == end_delim then -- End of an object or array.
        return nil, pos + 1
    else -- Parse true, false, or null.
        local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
        for lit_str, lit_val in pairs( literals ) do
            local lit_end = pos + #lit_str - 1
            if str:sub( pos, lit_end ) == lit_str then return lit_val, lit_end + 1 end
        end
        local pos_info_str = 'position ' .. pos .. ': ' .. str:sub( pos, pos + 10 )
        error( 'Invalid json syntax starting at ' .. pos_info_str )
    end
end
---@class MisDB
--- MisDB2 Main Object
local MisDB = {
    data_hook_read = function( data ) return json.parse( data ) end,
    data_hook_write = function( data ) return json.stringify( data ) end,
} ---@type MisDB

local function load_page( path )
    local ret
    local f = io.open( path, 'rb' )
    if f then
        ret = MisDB.data_hook_read( f:read( '*a' ) )
        f:close()
    end
    return ret
end
local function store_page( path, page )
    if page then
        local f = io.open( path, 'wb' )
        if f then
            f:write( MisDB.data_hook_write( page ) )
            f:close()
            return true
        end
    end
    return false
end

local pool = {}

local db_funcs = {
    save = function( db, p )
        if p then
            if (type( p ) == 'string') and db[p] then
                return store_page( pool[db] .. '/' .. p, db[p] )
            else
                return false
            end
        end
        for p, page in pairs( db ) do
            if not store_page( pool[db] .. '/' .. p, page ) then return false end
        end
        return true
    end,
}
local mt = {
    __index = function( db, k )
        if db_funcs[k] then return db_funcs[k] end
        if isFile( pool[db] .. '/' .. k ) then db[k] = load_page( pool[db] .. '/' .. k ) end
        return rawget( db, k )
    end,
}
pool.hook = db_funcs
local dbcontroller = setmetatable( pool, {
    __mode = 'kv',
    __call = function( pool, path )
        assert( isDir( path ), path .. ' is not a directory.' )
        if pool[path] then return pool[path] end
        local db = {}
        setmetatable( db, mt )
        pool[path] = db
        pool[db] = path
        return db
    end,
} )

function MisDB:new( baseDir )
    if (not baseDir) then return false, 'invalid basedir' end
    local dbDir = getPath( './MisDB_Data', baseDir )
    self.baseDir = dbDir
    if (not isDir( dbDir )) then mkDir( dbDir ) end
    self.Collections = {}
end

---@class MisDB.Collection
local collection = {}

function collection:new( source ) self.data = (source or {}) end

function collection:GetPage( pageId )
    local data = self.data[pageId]
    if (data == nil) or (data == json.null) then
        return false, 'no page data for pageId:' .. pageId
    end
    return self.data[pageId]
end

function collection:SetPage( pageId, data )
    self.data[pageId] = (data or json.null)
    self.data:save()
    local dataRead, result = self:GetPage( pageId )
    if dataRead then
        if result == data then
            return true, 'Page Data updated'
        else
            return false, 'failed to update Page Data'
        end
    end
    return false, 'failed to verify Page Data'
end

function collection:Save( pageId ) return self.data:save( pageId ) end

local Collection = Callable( collection )

function MisDB:Collection( name )
    if not self.Collections[name] then
        local collectionDir = getPath( self.baseDir, name )
        if not isDir( collectionDir ) then mkDir( collectionDir ) end
        self.Collections[name] = dbcontroller( getPath( self.baseDir, name ) )
    end
    return Collection( self.Collections[name] )
end

MisDB = Callable( MisDB )

---@class MisDB.DataStore
---@field DataSource table
---@field new fun(self:DataStore,config:ConfigStore_Options|nil):DataStore
local DataStore = {}
---* Defines a MisDB Backed Key/Value storage

---* DataStore(config)
-- Create a New DataStore
---@param config table Config
---@usage
--      local DataStore = require("UniversalRBA.Classes.DataStore")
--      local MyClass = Class {}
--      function MyClass:new()
--          self.DataStore = DataStore {name = 'DataStoreName', persistance_dir = 'dataDir'}
--      end
function DataStore:new( config )
    if not type( config ) == 'table' then
        return nil, 'you must provide a DataStore config'
    elseif not config['persistance_dir'] then
        return nil, 'must specify persistance_dir'
    elseif not config['name'] then
        return nil, 'must specify a name'
    end
    self.DataSource = {
        Source = MisDB( config.persistance_dir ), ---@type MisDB2
    }
    self.DataSource['Data'] = self.DataSource['Source']:Collection( config.name ) ---@type MisDB2_Collection
    return self
end
---* Fetches a Value from this DataStore
---@param key string ConfigKey
---@return number|string|table|boolean ConfigValue
function DataStore:GetValue( key )
    local Cache = (self.DataSource['Data'] or {})
    return Cache.data[key]
end
---* Saves a Value to this DataStore
---@param key string ConfigKey
---@param value number|string|table|boolean Value
---@return boolean Successfull
function DataStore:SetValue( key, value )
    local Cache = (self.DataSource['Data'] or {})
    Cache.data[key] = value
    res = self.DataSource.Data:Save()
    return res
end

MisDB.DataStore = Callable( DataStore )
RegisterModule( 'MisDB.DataStore', MisDB.DataStore )

--- EXPORTS
local exports = MisDB
-- RegisterModule('mFramework.Modules.MisDB2', exports)

RegisterModule( 'MisDB', exports )
return exports
