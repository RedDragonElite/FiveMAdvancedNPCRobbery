local Config = require('config')

-- Table to keep track of active stashes with their creation time
local activeStashes = {}

-- Function to check if inventory is empty
local function IsInventoryEmpty(stashId)
    local inventory = exports.ox_inventory:GetInventory(stashId)
    return not inventory or not inventory.items or #inventory.items == 0
end

-- Function to clean up a specific stash
local function CleanupStash(stashId)
    if activeStashes[stashId] then
        exports.ox_inventory:ClearInventory(stashId)
        TriggerClientEvent('npc_robbery:removeStashMarker', -1, stashId)
        activeStashes[stashId] = nil
        print(string.format("[RDE | Ped Robbery] Cleaned up empty stash: %s", stashId))
    end
end

-- Function to clean up old stashes
local function CleanupOldStashes()
    local currentTime = os.time()
    for stashId, data in pairs(activeStashes) do
        -- Clean up if older than 15 minutes or empty
        if currentTime - data.createdAt > 900 or IsInventoryEmpty(stashId) then
            CleanupStash(stashId)
        end
    end
end

local function CreateDropStash(coords, playerId, forcedLootType)
    if not coords then return end

    local stashId = string.format('npc_drop_%s_%s', os.time(), math.random(1000, 9999))

    -- Make stash accessible to everyone
    exports.ox_inventory:RegisterStash(stashId, 'Dropped Loot', 30, 100000, nil)
    print("[RDE | Ped Robbery] Created stash:", stashId)

    activeStashes[stashId] = {
        createdAt = os.time(),
        coords = coords
    }

    local lootType = forcedLootType or (math.random(1, 100) <= 50 and "money" or "items")
    local minCash = Config.MinCash or 100
    local maxCash = Config.MaxCash or 1000

    if lootType == "money" then
        local amount = math.random(minCash, maxCash)
        local success = exports.ox_inventory:AddItem(stashId, 'money', amount)
        if success then
            print("[RDE | Ped Robbery] Added money to stash:", amount)
        else
            print("[RDE | Ped Robbery] Failed to add money to stash")
        end
    elseif Config.Items and type(Config.Items) == 'table' then
        local itemAdded = false
        for _, item in ipairs(Config.Items) do
            if item and item.chance and item.name and item.min and item.max then
                if math.random(1, 100) <= item.chance then
                    local count = math.random(item.min, item.max)
                    local success = exports.ox_inventory:AddItem(stashId, item.name, count)
                    if success then
                        itemAdded = true
                        print(string.format("[RDE | Ped Robbery] Added %d %s to stash", count, item.name))
                    else
                        print(string.format("[RDE | Ped Robbery] Failed to add %s to stash", item.name))
                    end
                end
            end
        end

        -- If no items were added, add at least one random item
        if not itemAdded and #Config.Items > 0 then
            local randomItem = Config.Items[math.random(#Config.Items)]
            local count = math.random(randomItem.min, randomItem.max)
            local success = exports.ox_inventory:AddItem(stashId, randomItem.name, count)
            if success then
                print(string.format("[RDE | Ped Robbery] Added fallback item %d %s to stash", count, randomItem.name))
            end
        end
    end

    -- Notify all players about the new stash
    TriggerClientEvent('npc_robbery:createStashMarker', -1, stashId, coords, lootType)

    return stashId
end

-- Check inventories every 30 seconds
CreateThread(function()
    while true do
        Wait(30000) -- 30 seconds
        CleanupOldStashes()
    end
end)

-- Listen for inventory changes
AddEventHandler('ox_inventory:inventoryChanged', function(inventoryId, changes)
    if activeStashes[inventoryId] and IsInventoryEmpty(inventoryId) then
        CleanupStash(inventoryId)
    end
end)

-- Send active stashes to new players
RegisterNetEvent('npc_robbery:requestStashes', function()
    local source = source
    for stashId, data in pairs(activeStashes) do
        -- Only send if stash still has items
        if not IsInventoryEmpty(stashId) then
            -- Determine loot type based on inventory contents
            local inventory = exports.ox_inventory:GetInventory(stashId)
            local lootType = "items"
            if inventory and inventory.items then
                for _, item in ipairs(inventory.items) do
                    if item.name == "money" then
                        lootType = "money"
                        break
                    end
                end
            end
            TriggerClientEvent('npc_robbery:createStashMarker', source, stashId, data.coords, lootType)
        else
            CleanupStash(stashId) -- Clean up if empty
        end
    end
end)

RegisterNetEvent('npc_robbery:dropLoot', function(coords, lootType)
    local source = source
    if not source then return end

    local success, result = pcall(function()
        return CreateDropStash(coords, source, lootType)
    end)

    if not success then
        print("[RDE | Ped Robbery] Error in CreateDropStash:", result)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("[RDE | Ped Robbery] Cleaning up all stashes...")
        for stashId, _ in pairs(activeStashes) do
            exports.ox_inventory:ClearInventory(stashId)
        end
        TriggerClientEvent('npc_robbery:removeAllStashMarkers', -1)
        activeStashes = {}
    end
end)
