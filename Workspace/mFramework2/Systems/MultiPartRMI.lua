local player = {GetName = function() return 'Theros' end, player = {GetSteam64Id = function() return '7299219293923' end}}
g_MultipartRMI_Cache = {send = {}, recieve = {}}

local multipartParser = coroutine.wrap(function(steamId, transaction, data)
    local cache = g_MultipartRMI_Cache[steamId]
    --- create initial data cache
    if not cache[transaction.id] then cache[transaction.id] = "" end
    local compleated = false
    while (not compleated) do
        cache[transaction.id] = cache[transaction.id] .. data
        if (transaction.chunk >= transaction.chunks) then
            compleated = true
        else
            steamId,transaction, data = coroutine.yield(false)
        end
    end
    return cache[transaction.id]
end)
---[internal] recieve a MultipartRMI
---@param player entity
---@param transaction table<string,number> `id:number, chunks:number, chunk:number`
---@param data string
local function RecieveMultipart(player, transaction, data,cb)
    local steamId = player.player:GetSteam64Id()
    --- ensure we have a cache for this player
    if (not g_MultipartRMI_Cache[steamId]) then g_MultipartRMI_Cache[steamId] = {} end
    local result = multipartParser(steamId,transaction,data)
    if result then
        cb(result)
    end
end

local onDataFinish = function(data)
    print("finished", data)
end


RecieveMultipart(player, {id = 1, chunk = 1, chunks = 3}, '{ "test":{ ',onDataFinish)
RecieveMultipart(player, {id = 1, chunk = 2, chunks = 3}, '"name": "theros", ',onDataFinish)
RecieveMultipart(player, {id = 1, chunk = 3, chunks = 3}, '"message":"hello" } }',onDataFinish)



