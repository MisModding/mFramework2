local SpawnTools = {}

function SpawnTools:SetCorrectStackSizes(SpawnedItems, AmountToSpawn)
    local lastStack = #SpawnedItems
    local CurrentStack = 1
    local AmountRemain = AmountToSpawn
    Log('   -> Spawning Items - Total %s in %s Stacks', tostring(AmountToSpawn), tostring(lastStack))
    for idx, item in ipairs(SpawnedItems) do
        if (item and item.item) then
            if CurrentStack ~= lastStack then
                item.item:SetStackCount(item.item:GetMaxStackSize())
                AmountRemain = (AmountRemain - item.item:GetStackCount())
            else
                item.item:SetStackCount(AmountRemain)
                AmountRemain = (AmountRemain - item.item:GetStackCount())
            end
            Log('Proccessed Stack: %s', tostring(CurrentStack))
            Log('Remaining: %s', tostring(AmountRemain))
            CurrentStack = CurrentStack + 1
        else
            Log('Invalid Item in SpawnedItems')
            return nil, 0, 'Invalid Item in SpawnedItems'
        end
    end
    return AmountRemain, 'Success Setting Item Stacks'
end

function SpawnTools:CalculateStacks(item, amount)
    local StacksRequired
    local MaxStackCount = item.item:GetMaxStackSize()
    if MaxStackCount >= amount then
        StacksRequired = 1
    else
        StacksRequired = math.ceil(amount / MaxStackCount)
    end
    return StacksRequired
end

function SpawnTools:SpawnAsStacks(playerId, itemClass, count, ...)
    local SpawnedItems = {}
    local MaxStackCount
    local AllSpawned
    local idx = 0
    local firstStack = true
    while not AllSpawned and idx <= count do
        idx = idx + 1
        local ItemSpawned = ISM.GiveItem(playerId, itemClass, ...)
        if ItemSpawned then
            if firstStack then
                Log('   -> FirstStack...')
                firstStack = false
                MaxStackCount = self:CalculateStacks(ItemSpawned, count)
                Log('   -> Calculated StackCount = %s', tostring(MaxStackCount))
            end
            InsertIntoTable(SpawnedItems, ItemSpawned)
            if idx >= MaxStackCount then
                Log('   -> AllSpawned')
                AllSpawned = true
            end
        else
            return nil, idx, 'Failed to Spawn Item'
        end
    end
    local Unstacked, StackError = self:SetCorrectStackSizes(SpawnedItems, count)
    if Unstacked ~= 0 then
        return nil, Unstacked, (StackError or 'Some Items couldnt Be Stacked')
    else
        return true, Unstacked, (StackError or 'Success Spawning Stacked Items')
    end
end

function SpawnTools:SetItemHealth(thisItem, Health)
    Log(' Checking if Item: ' .. thisItem.class .. ' is Destroyable')
    if type(thisItem.item.IsDestroyable) == 'function' then
        if thisItem.item:IsDestroyable() then
            local itemHealth = function(maxHP, percentHP)
                local n = maxHP * percentHP / 100
                return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
            end
            Log('Item: ' .. thisItem.class .. ' is Destroyable... Setting Max Health')
            thisItem.item:SetHealth(itemHealth(thisItem.item:GetMaxHealth(), Health))
        end
    else
        Log('Item: ' .. thisItem.class .. ' is NOT Destroyable')
    end
end

-- Gives a Player sets of items - @param items:string eg items="AK74U|5.45x39;DuffelBag|5.45x39|AmmoBox_5_45x39|GridMap|Bandage|DuctTape"
function SpawnTools:GiveItemSet(playerId, items)
    local itemList = {}
    -- seperate the items list at ";" seperator
    for item in (items .. ';'):gmatch('([^;]*);') do table.insert(itemList, item) end

    local itemSetList = {}
    -- Parse the itemlist into sets based on "," seperator
    for _, thisItem in pairs(itemList) do
        local ix = 0
        local itemKey = nil
        for subItem in (thisItem .. '|'):gmatch('([^|]*)|') do
            if ix ~= 1 then
                itemKey = subItem
                itemSetList[itemKey] = {}
                ix = 1
            else
                table.insert(itemSetList[itemKey], subItem)
            end
        end
    end
    -- Process ItemSets
    for Item, SubItems in pairs(itemSetList) do
        -- parse out the Item Name and Count from chuncks containing a *
        local itemCount = string.match(Item, '[*](%d+)')
        if itemCount ~= nil then
            itemCount = string.gsub(itemCount, '*', '')
            Item = string.gsub(Item, '*' .. itemCount, '')
        end
        -- Set iCount to itemCount to spawn
        local iCount = (tonumber(itemCount) or 1)
        Log(' Item: [' .. Item .. '] x' .. iCount)
        local itemGiven, itemParent = self:SpawnAsStacks(playerId, Item, iCount)
        if not itemGiven then
            Log('GiveItemSet Failed while Processing SubItems')
            return nil, 'failed while processing SubItems'
        end
        if not (SubItems:size() <= 0) then
            for _, thisItem in pairs(SubItems) do
                local subItemCount = string.match(thisItem, '[*](%d+)')
                if subItemCount ~= nil then
                    subItemCount = string.gsub(subItemCount, '*', '')
                    thisItem = string.gsub(thisItem, '*' .. subItemCount, '')
                end

                local siCount = (tonumber(subItemCount) or 1)
                Log('Sub Item -> [' .. thisItem .. '] x' .. siCount)
                local SubItemGiven, _ = self:SpawnAsStacks(playerId, thisItem, siCount, itemParent)
                if not SubItemGiven then
                    Log('GiveItemSet Failed while Processing SubItem: ' .. thisItem)
                    return nil, 'failed while processing SubItems'
                end
            end
        end
    end
end

function SpawnTools:GetSpawnPos(player, offset)
    local vForwardOffset = {x = 0, y = 0, z = 0}
    FastScaleVector(vForwardOffset, player:GetDirectionVector(), offset)
    local vSpawnPos = {x = 0, y = 0, z = 0}
    FastSumVectors(vSpawnPos, vForwardOffset, player:GetWorldPos())
    return vSpawnPos
end

_G['mSpawnTools'] = SpawnTools
