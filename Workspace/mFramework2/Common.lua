DIR_SEPERATOR = _G['package'].config:sub( 1, 1 )

---* Return the Size of a Table.
-- Works with non Indexed Tables
--- @param table table  `any table to get the size of`
--- @return number      `size of the table`
function table.size( table )
    local n = 0
    for k, v in pairs( table ) do n = n + 1 end
    return n
end

--- Return an array of keys of a table.
---@param tbl table `The input table.`
---@return table `The array of keys.`
function table.keys( tbl )
    local ks = {}
    for k, _ in pairs( tbl ) do table.insert( ks, k ) end
    return ks
end

---* Copies all the fields from the source into t and return .
-- If a key exists in multiple tables the right-most table value is used.
--- @param t table      table to update
function table.update( t, ... )
    for i = 1, select( '#', ... ) do
        local x = select( i, ... )
        if x then for k, v in pairs( x ) do t[k] = v end end
    end
    return t
end

if not table.pack then table.pack = function( ... ) return {n = select( '#', ... ), ...} end end

function table.each( t, f ) for index, value in pairs( t ) do f( value, index ) end end

--- safely escape a given string
---@param str string    string to escape
string.escape = function( str ) return str:gsub( '([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1' ) end

--- Split a string at a given string as delimeter (defaults to a single space)
-- | local str = string.split('string | to | split', ' | ') -- split at ` | `
-- >> str = {"string", "to", "split"}
---@param str string        string to split
---@param delimiter string  optional delimiter, defaults to " "
string.split = function( str, delimiter )
    local result = {}
    local from = 1
    local delim = delimiter or ' '
    local delim_from, delim_to = string.find( str, delim:escape(), from )
    while delim_from do
        table.insert( result, string.sub( str, from, delim_from - 1 ) )
        from = delim_to + 1
        delim_from, delim_to = string.find( str, delim, from )
    end
    table.insert( result, string.sub( str, from ) )
    return result
end

--- extracts key=value styled arguments from a given string
---@param str string string to extract args from
---@return table args table containing any found key=value patterns
string.kvargs = function( str )
    local t = {}
    for k, v in string.gmatch( str, '(%w+)=(%w+)' ) do t[k] = v end
    return t
end

---* decode a hex encoded string
---@param str string `the string to decode`
---@return string `decoded Hex string`
function string.fromHex( str )
    return (str:gsub( '..', function( cc ) return string.char( tonumber( cc, 16 ) ) end ))
end

---* encode a string to Hex
---@param str string `the string to Hex encode`
---@return string `Hex Encoded String`
function string.toHex( str )
    return (str:gsub( '.', function( c ) return string.format( '%02X', string.byte( c ) ) end ))
end

--- expand a string containing any `${var}` or `$var`.
--- Substitution values should be only numbers or strings.
--- @param s string the string
--- @param subst any either a table or a function (as in `string.gsub`)
--- @return string expanded string
function string.expand( s, subst )
    local res, k = s:gsub( '%${([%w_]+)}', subst )
    if k > 0 then return res end
    return (res:gsub( '%$([%w_]+)', subst ))
end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do table.insert( charset, string.char( c ) ) end
    for c = 65, 90 do table.insert( charset, string.char( c ) ) end
    for c = 97, 122 do table.insert( charset, string.char( c ) ) end
end

---* Cleans Eccess quotes from input string
function clean_quotes( inputString )
    local result
    result = inputString:gsub( '^"', '' ):gsub( '"$', '' )
    result = result:gsub( '^\'', '' ):gsub( '\'$', '' )
    return result
end

--- generate a random string with a given length
---@param	length number num chars to generate
---@return	string
function RandomString( length )
    if not length or length <= 0 then return '' end
    math.randomseed( os.clock() ^ 5 )
    return RandomString( length - 1 ) .. charset[math.random( 1, #charset )]
end

function Dec2Hex( nValue )
    if type( nValue ) == 'string' then nValue = tonumber( nValue ) end
    local nHexVal = string.format( '%X', nValue ) -- %X returns uppercase hex, %x gives lowercase letters
    local sHexVal = nHexVal .. ''
    return sHexVal
end

function Hex2Dec( someHexString ) return tonumber( someHexString, 16 ) end

---* Evaluate a Lua String
--- evaluates `eval_string` in Protected mode, Does nothing if the provided string
--- contains errors or is not a valid lua chunk, else returns boolean,result
---@param eval_string string
---@return boolean success
---@return any result
function eval_string( eval_string )
    if not type( eval_string ) == 'string' then
        return
    else
        local eString = eval_string:gsub( '%^%*', ',' ):gsub( '%*%^', ',' )
        local eval_func = function( s ) return loadstring( s )() end
        return pcall( eval_func, eString )
    end
end

--
-- ────────────────────────────────────────────────────── GETTERS AND SETTERS ─────
--

-- @function compose
---* Create a function composition from given functions.
-- any further functions as arguments get added to composition in order
--- @param f1 function
-- the outermost function of the composition
--- @param f2 function
-- second outermost function of the composition
--- @return function the composite function
function compose( f1, f2, ... )
    if select( '#', ... ) > 0 then
        local part = compose( f2, ... )
        return compose( f1, part )
    else
        return function( ... ) return f1( f2( ... ) ) end
    end
end

-- @function bind
---* Create a function with bound arguments ,
-- The bound function returned will call func() ,
-- with the arguments passed on to its creation .
-- If more arguments are given during its call, they are ,
-- appended to the original ones .
-- `...` the arguments to bind to the function.
--- @param func function
-- the function to create a binding of
--- @return function
-- the bound function
function bind( func, ... )
    local saved_args = {...}
    return function( ... )
        local args = {table.unpack( saved_args )}
        for _, arg in ipairs( {...} ) do table.insert( args, arg ) end
        return func( table.unpack( args ) )
    end
end

-- @function bind_self
---* Create f bound function whose first argument is t ,
--  Particularly useful to pass a method as a function ,
-- Equivalent to bind(t[k], t, ...) ,
-- `...` further arguments to bind to the function.
--- @param t table Binding
-- The table to be accessed
--- @param k any Key
-- The key to be accessed
--- @return function BoundFunc
-- The binding for t[k]
function bind_self( t, k, ... ) return bind( t[k], t, ... ) end

---* Create a function that returns the value of t[k] ,
-- | The returned function is Bound to the Provided Table,Key.
--- @param t table      table to access
--- @param k any        key to return
--- @return function returned getter function
function bind_getter( t, k )
    return function()
        if (not type( t ) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            return t[k], 'Fetched Bound Key'
        end
    end
end

---* Create a function that sets the value of t[k] ,
--- The returned function is Bound to the Provided Table,Key ,
--- The argument passed to the returned function is used as the value to set.
--- @param t table       table to access
--- @param k table       key to set
--- @return function     returned setter function
function bind_setter( t, k )
    return function( v )
        if (not type( t ) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            t[k] = v
            return true, 'Set Bound Key'
        end
    end
end

---* Create a function that returns the value of t[k] ,
--- The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned getter function
function getter( t )
    if (not type( t ) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function( k ) return t[k] end
    end
end

---* Create a function that sets the value of t[k] ,
--- The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned setter function
function setter( t )
    if (not type( t ) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function( k, v )
            t[k] = v
            return true
        end
    end
end

--
-- ──────────────────────────────────────────────────────────────────── EXTRA ─────
--

--- load and execute a lua script from a given path
function RequireFile( filename )
    local oldPackagePath = package.path
    package.path = './' .. filename .. ';' .. package.path
    local obj = require( filename )
    package.path = oldPackagePath
    if obj then
        return obj, 'success loading file from ' .. filename
    else
        return nil, 'Failed to Require file from path ' .. filename
    end
end

local function import_symbol( T, k, v, libname )
    local key = rawget( T, k )
    -- warn about collisions!
    if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
        Log( 'warning: \'%s.%s\' will not override existing symbol\n', libname, k )
        return
    end
    rawset( T, k, v )
end

local function lookup_lib( T, t )
    for k, v in pairs( T ) do if v == t then return k end end
    return '?'
end

local already_imported = {}

---* take a table and 'inject' it into the local namespace.
--- @param t table
-- The Table
--- @param T  table
-- An optional destination table (defaults to callers environment)
function Import( t, T )
    T = T or _G
    if type( t ) == 'string' then t = require( t ) end
    local libname = lookup_lib( T, t )
    if already_imported[t] then return end
    already_imported[t] = libname
    for k, v in pairs( t ) do import_symbol( T, k, v, libname ) end
end

local function Invoker( links, index )
    return function( ... )
        local link = links[index]
        if not link then return end
        local continue = Invoker( links, index + 1 )
        local returned = link( continue, ... )
        if returned then returned( function( _, ... ) continue( ... ) end ) end
    end
end

---* used to chain multiple functions/callbacks
-- Example
-- local function TimedText (seconds, text)
--     return function (go)
--         print(text)
--         millseconds = (seconds or 1) * 1000
--         Script.SetTimerForFunction(millseconds, go)
--     end
-- end
--
-- Chain(
--     TimedText(1, 'fading in'),
--     TimedText(1, 'showing splash screen'),
--     TimedText(1, 'showing title screen'),
--     TimedText(1, 'showing demo')
-- )()
---@return function chain
-- the cretedfunction chain
function Chain( ... )
    local links = {...}

    local function chain( ... )
        if not (...) then return Invoker( links, 1 )( select( 2, ... ) ) end
        local offset = #links
        for index = 1, select( '#', ... ) do links[offset + index] = select( index, ... ) end
        return chain
    end

    return chain
end

---* Used for Grabbing Data Logged to Console/Logfile from function `f` ,
-- this only grabs the Data Logged During the provdided function call ,
-- and returns Raw Log output.
---@param f function
-- a function to Rip Log Output from
-- any further parameters are passed to your function `f(...)`
---@return string
-- LogData - A string Containging Raw Captured Log Data
function LogRipper( f, ... )
    local mode = nil
    if System.IsEditor() then
        mode = 0
    elseif (not System.IsEditor()) and (CryAction.IsDedicatedServer()) then
        mode = 1
    elseif (not System.IsEditor()) and (CryAction.IsClient()) then
        mode = 2
    end
    local function getFile( offset )
        local logfile = nil
        if mode == 0 then
            logfile = io.open( 'editor.log', 'r' )
        elseif mode == 1 then
            logfile = io.open( 'server.log', 'r' )
        elseif mode == 2 then
            logfile = io.open( 'game.log', 'r' )
        end
        if logfile then
            if offset then logfile:seek( 'set', offset ) end
            return logfile
        end
    end
    local _logfile = getFile()
    if _logfile then
        local filepos = _logfile:seek( 'end' )
        _logfile:close()
        f( ... )
        if filepos then
            local logfile = getFile( filepos )
            if logfile then
                local fileRip = logfile:read( '*all' )
                logfile:close()
                if fileRip then return fileRip end
            end
        end
        return nil
    end
end

--- initTime, the returned os.time() saved when this file was first read
local initTime = os.time()

--- improved randomseed function accouning for lua 5.1 vm limitations
--- Lua 5.1 has a limitation on the bitsize meaning that when using randomseed
--- numbers over the limit get truncated or set to 1 , destroying all randomness for the run
--- uses an assumed Lua 5.1 maximim bitsize of 32.
---@param seed number optional: number used to preseed the randomseed function (defaults to the value of initTime)
function better_randomseed( seed )
    local bitsize = 32
    seed = math.floor( math.abs( seed or initTime ) )
    if seed >= (2 ^ bitsize) then
        -- integer overflow, reduce  it to prevent a bad seed.
        seed = seed - math.floor( seed / 2 ^ bitsize ) * (2 ^ bitsize)
    end
    math.randomseed( seed - 2 ^ (bitsize - 1) )
    return seed
end


---@alias UUID string UniqueID
--- Generate a new UUID
---@return UUID, string
function UUID()
    local uuidSeed = better_randomseed( initTime )
    local function UUID( prefix )
        local template = 'xyxxxxxx-xxyx-xxxy-yxxx-xyxxxxxxxxxx'
        local mutator = function( c )
            local v = (c == 'x') and math.random( 0, 0xf ) or math.random( 8, 0xb )
            return string.format( '%x', v )
        end
        return string.gsub( template, '[xy]', mutator )
    end
    return UUID(), uuidSeed
end

---* bind an argument to a type and throw an error if the provided param doesnt match at runtime.
-- Note this works in reverse of the normal assert in that it returns nil if the argumens provided are valid
-- if not the it either returns true plus and error message , or if it fails to grab debug info just true.
--- @param idx number
-- positonal index of the param to bind
--- @param val any the param to bind
--- @param tp string the params bound type
--- @usage
-- local test = function(somearg,str,somearg)
-- if assert_arg(2,str,'string') then
--    return
-- end
--
-- test(nil,1,nil) -> Invalid Param in [test()]> Argument:2 Type: number Expected: string
function assert_arg( idx, val, tp )
    if type( val ) ~= tp then
        local fn = debug.getinfo( 2, 'n' )
        local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
                      string.format( 'Argument:%s Type: %q Expected: %q', tostring( idx ),
                        type( val ), tp )
        local test = function() error( msg, 4 ) end
        local rStat, cResult = pcall( test )
        if rStat then
            return true
        else
            LogError( cResult )
            return true, cResult
        end
    end
end

--- Used for patching CVars at runtime.
function PatchVars( vars )
    if (vars) then
        for key, value in pairs( vars ) do
            local currentVal = System.GetCVar( key )
            if (currentVal ~= value) then
                Log( ' - var: ' .. key .. ' Needs Patching' )
                Log( ' - Current = ' .. tostring( currentVal ) .. ' -- New = ' .. tostring( value ) )
                System.SetCVar( key, value )
            else
                Log( ' - var: ' .. key .. ' OK' )
                Log( ' - Current = ' .. tostring( currentVal ) .. ' -- Expected = ' ..
                       tostring( value ) )
            end
        end
    end
end

-- @function OnlyRunOnce
---* Function Wrapper Explicitly ensures the Provided Function Only Runs Once (Does not work with anon funcs)
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function OnlyRunOnce( f, ... )
    if not _G['Script_RunOnce'] then _G['Script_RunOnce'] = {} end
    for k, v in pairs( _G['Script_RunOnce'] ) do if (v == f) then return end end
    table.insert( Script_RunOnce, f )
    f( ... )
end

-- @function ServerOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Server.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ServerOnly( f, ... )
    if System.IsEditor() or CryAction.IsDedicatedServer() then return f( ... ) end
end

-- @function ClientOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Client.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ClientOnly( f, ... ) if System.IsEditor() or CryAction.IsClient() then return f( ... ) end end

--- recursive read-only definition
function readOnly( t )
    for x, y in pairs( t ) do
        if type( x ) == 'table' then
            if type( y ) == 'table' then
                t[readOnly( x )] = readOnly[y]
            else
                t[readOnly( x )] = y
            end
        elseif type( y ) == 'table' then
            t[x] = readOnly( y )
        end
    end

    local proxy = {}
    local mt = {
        -- hide the actual table being accessed
        __metatable = 'read only table',
        __index = function( tab, k ) return t[k] end,
        __pairs = function() return pairs( t ) end,
        __newindex = function( t, k, v ) error( 'attempt to update a read-only table', 2 ) end,
    }
    setmetatable( proxy, mt )
    return proxy
end

local oldpairs = pairs
function pairs( t )
    local mt = getmetatable( t )
    if mt == nil then
        return oldpairs( t )
    elseif type( mt.__pairs ) ~= 'function' then
        return oldpairs( t )
    end

    return mt.__pairs()
end

function clone_function( fn )
    local dumped = string.dump( fn )
    local cloned = loadstring( dumped )
    local i = 1
    while true do
        local name, value = debug.getupvalue( fn, i )
        if not name then break end
        debug.setupvalue( fn, i, value )
        i = i + 1
    end
    return cloned
end

local function split_command( str, delimiter )
    local result = {}
    local from = 1
    local delim = delimiter or ' '
    local delim_from, delim_to = string.find( str, delim, from )
    while delim_from do
        table.insert( result, string.sub( str, from, delim_from - 1 ) )
        from = delim_to + 1
        delim_from, delim_to = string.find( str, delim, from )
    end
    table.insert( result, string.sub( str, from ) )
    return result
end

local function parse_kvargs( str )
    local t = {}
    -- note: currently only supports 3 spaces or 3 punctuation symbols in a value
    for k, v in string.gmatch( str, '-(%w+)=(%w+%p?%s?%w+%p?%s?%w+)' ) do t[k] = v end
    return t
end

parseCommand = function( command )
    local parsed = {}
    local command_parts = split_command( command )
    if command_parts then
        parsed.cmd = command_parts[1]
        parsed.arg0 = command:gsub( command_parts[1], '' ):gsub( '^%s', '' )
        parsed.args = command_parts
        table.remove( parsed.args, 1 )
        parsed.kvargs = parse_kvargs( command )
        ---HACK: cleanup any kvargs from args
        for k in pairs( parsed['kvargs'] ) do
            for i, value in ipairs( parsed['args'] ) do
                if string.find( value, '-' .. k ) then table.remove( parsed.args, i ) end
            end
        end
        return parsed
    else
        return command
    end
end


local betterRandom = function(...)
    better_randomseed(os.clock())
    return math.random(...)
end

--- ServerOnly: Fetch a random player
---@param list table<number,player> table of players to choose from eg: `local chosenPlayer = GetRandomPlayer(CryAction.GetPlayerList())`
function GetRandomPlayer(list)
    math.randomseed(os.time)
    local players = (list or (CryAction.GetPlayerList() or {}))
    if (players == {}) then return end
    if #players > 1 then
        return players[betterRandom(#players)]
    else
        return players[1]
    end
end