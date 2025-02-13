local Config = require('config')

local isRobbing = false
local currentVictim = nil
local activeStashes = {}
local activeProps = {}
local language = "English"
local processingPeds = {}
local lastRobberyTime = 0
local ROBBERY_COOLDOWN = 15000 -- 15 seconds

-- Prop models for different loot types
local propModels = {
    money = {
        'prop_money_bag_01',
        'prop_cash_pile_02',
        'prop_cash_case_02'
    },
    items = {
        'prop_cs_cardbox_01',
        'prop_box_ammo04a',
        'prop_box_tea01a',
        'prop_paper_bag_01'
    }
}

-- Optimized entity check function
local function IsValidPedForRobbery(ped)
    return DoesEntityExist(ped) 
        and not IsPedAPlayer(ped) 
        and not IsPedDeadOrDying(ped, true) 
        and not IsPedInAnyVehicle(ped, false)  -- Changed to false
        and not processingPeds[ped]
        and not isRobbing
        and NetworkGetEntityIsNetworked(ped)
end

-- Function to check if player is near a stash
local function IsNearStash()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for stashId, stashData in pairs(activeStashes) do
        local checkCoords = stashData.prop and GetEntityCoords(stashData.prop) or stashData.coords
        local dist = #(playerCoords - checkCoords)
        if dist < 2.0 then
            return stashId, stashData
        end
    end
    return nil, nil
end

-- Function to check if weapon is aimed at ped
local function IsWeaponAimedAtPed(ped)
    local player = PlayerPedId()
    if not IsPedArmed(player, 7) then return false end

    local _, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    return targetEntity == ped
end

-- Optimized prop creation function
local function CreateLootProp(coords, lootType)
    local modelList = propModels[lootType] or propModels.items
    local modelHash = joaat(modelList[math.random(#modelList)])

    lib.requestModel(modelHash)

    -- Randomized offset for more natural prop placement
    local offset = vec3(
        math.random(-10, 10) * 0.1,
        math.random(-10, 10) * 0.1,
        0.0
    )
    
    local propCoords = vec3(
        coords.x + offset.x,
        coords.y + offset.y,
        coords.z - 0.5
    )

    local prop = CreateObject(modelHash, propCoords.x, propCoords.y, propCoords.z, true, true, true)
    
    if prop and DoesEntityExist(prop) then
        SetEntityHasGravity(prop, true)
        SetEntityDynamic(prop, true)
        FreezeEntityPosition(prop, false)
        SetEntityVelocity(prop, 0.0, 0.0, -0.2)
        
        SetEntityRotation(prop,
            math.random() * 360.0,
            math.random() * 360.0,
            math.random() * 360.0,
            2,
            true
        )
        
        -- Ensure network visibility
        NetworkRegisterEntityAsNetworked(prop)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(prop), true)
    end

    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

-- Optimized hostile ped handling
local function HandleHostilePed(ped)
    if not IsValidPedForRobbery(ped) then return end
    
    processingPeds[ped] = true
    local player = PlayerPedId()
    
    -- Sofort Combat-Attribute setzen
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 2, true)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 3)
    SetPedCombatAbility(ped, 100)
    SetPedAccuracy(ped, 60)
    
    -- Waffen-Logik vor der Combat-Task
    if math.random(100) <= Config.ChanceToHaveWeapon then
        local weapon = Config.WeaponsList[math.random(#Config.WeaponsList)]
        GiveWeaponToPed(ped, joaat(weapon), 100, false, true)
    end

    -- Direkt Combat-Task setzen ohne Verzögerung
    TaskCombatPed(ped, player, 0, 16)
    
    lib.notify({
        title = 'Hostile NPC',
        description = Config.Texts[language].HostileNPCAttacking,
        type = 'error'
    })

    -- Längere Verarbeitungszeit
    SetTimeout(15000, function()
        if DoesEntityExist(ped) then
            processingPeds[ped] = nil
        end
    end)
end

-- Optimized cooperative ped handling
local function HandleCooperativePed(ped)
    if not IsValidPedForRobbery(ped) or isRobbing then return end
    
    -- Cooldown check
    local currentTime = GetGameTimer()
    if currentTime - lastRobberyTime < ROBBERY_COOLDOWN then
        local remainingCooldown = math.ceil((ROBBERY_COOLDOWN - (currentTime - lastRobberyTime)) / 1000)
        lib.notify({
            title = 'Robbery Cooldown',
            description = string.format('Wait %d seconds before robbing again', remainingCooldown),
            type = 'error'
        })
        return
    end
    
    processingPeds[ped] = true
    isRobbing = true
    currentVictim = ped
    lastRobberyTime = currentTime
    
    -- Ensure ped is networked
    if not NetworkGetEntityIsNetworked(ped) then
        NetworkRegisterEntityAsNetworked(ped)
    end
    
    -- Robbery sequence
    ClearPedTasksImmediately(ped)
    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 1000)
    Wait(1000)
    
    local pedCoords = GetEntityCoords(ped)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)

    lib.notify({
        title = 'Robbery',
        description = Config.Texts[language].RobberyCooperating,
        type = 'success'
    })

    -- Animation sequence
    lib.requestAnimDict('missminuteman_1ig_2')
    TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Trigger loot drop
    TriggerServerEvent('npc_robbery:dropLoot', pedCoords)
    
    -- Delayed escape sequence
    SetTimeout(5000, function()
        if DoesEntityExist(ped) then
            TaskAimGunAtCoord(ped, 
                pedCoords.x + math.random(-2, 2), 
                pedCoords.y + math.random(-2, 2), 
                pedCoords.z, 
                1000, false, false
            )
            
            SetTimeout(1000, function()
                if DoesEntityExist(ped) then
                    SetBlockingOfNonTemporaryEvents(ped, false)
                    ClearPedTasks(ped)
                    SetPedFleeAttributes(ped, 2, true)
                    TaskSmartFleePed(ped, PlayerPedId(), 100.0, -1, true, false)
                end
            end)
        end
    end)

    -- Reset states
    SetTimeout(6000, function()
        isRobbing = false
        currentVictim = nil
        if DoesEntityExist(ped) then
            processingPeds[ped] = nil
        end
    end)
end

-- Main handler for ped reactions
local function HandlePedReaction(ped)
    if not IsValidPedForRobbery(ped) then return end
    
    -- Determine hostility
    if math.random(100) <= Config.ChanceToBeHostile then
        HandleHostilePed(ped)
    else
        HandleCooperativePed(ped)
    end
end

-- Network events
RegisterNetEvent('npc_robbery:createStashMarker', function(stashId, coords, lootType)
    if activeStashes[stashId] then return end

    activeStashes[stashId] = {
        coords = coords,
        lootType = lootType,
        prop = nil
    }

    local prop = CreateLootProp(coords, lootType)
    if prop and DoesEntityExist(prop) then
        activeStashes[stashId].prop = prop
        activeProps[prop] = stashId
    end

    lib.notify({
        title = 'Loot Available',
        description = lootType == "money" 
            and Config.Texts[language].LootAvailableMoney 
            or Config.Texts[language].LootAvailableItems,
        type = 'success'
    })
end)

RegisterNetEvent('npc_robbery:removeStashMarker', function(stashId)
    if not activeStashes[stashId] then return end
    
    if activeStashes[stashId].prop and DoesEntityExist(activeStashes[stashId].prop) then
        DeleteObject(activeStashes[stashId].prop)
        activeProps[activeStashes[stashId].prop] = nil
    end
    activeStashes[stashId] = nil
end)

RegisterNetEvent('npc_robbery:removeAllStashMarkers', function()
    for stashId, stashData in pairs(activeStashes) do
        if stashData.prop and DoesEntityExist(stashData.prop) then
            DeleteObject(stashData.prop)
        end
    end
    activeStashes = {}
    activeProps = {}
end)

-- Stash interaction thread
CreateThread(function()
    while true do
        local wait = 1000
        local stashId, stashData = IsNearStash()

        if stashId then
            wait = 0
            AddTextEntry('NPC_INTERACT', Config.Texts[language].PressToOpenLoot)
            DisplayHelpTextThisFrame('NPC_INTERACT', false)

            if IsControlJustReleased(0, 38) then
                TriggerEvent('ox_inventory:openInventory', 'stash', {id = stashId})
                Wait(500)
            end
        end

        Wait(wait)
    end
end)

-- Initial stash request
CreateThread(function()
    Wait(2000) -- Wait for network to be ready
    TriggerServerEvent('npc_robbery:requestStashes')
end)

-- Optimized main game loop
CreateThread(function()
    while true do
        local wait = 1000
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)
        local hasTarget = false

        local peds = GetGamePool('CPed')
        for _, ped in ipairs(peds) do
            if IsValidPedForRobbery(ped) then
                local dist = #(playerCoords - GetEntityCoords(ped))
                if dist < 20.0 then
                    wait = 0
                    if IsWeaponAimedAtPed(ped) then
                        hasTarget = true
                        HandlePedReaction(ped)
                        break -- Fokus auf einen NPC
                    end
                end
            end
        end

        if hasTarget then
            wait = 0
        end

        Wait(wait)
    end
end)

-- Cleanup handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for stashId, stashData in pairs(activeStashes) do
            if stashData.prop and DoesEntityExist(stashData.prop) then
                DeleteObject(stashData.prop)
            end
        end

        if currentVictim and DoesEntityExist(currentVictim) then
            ClearPedTasks(currentVictim)
        end
        
        processingPeds = {}
        isRobbing = false
        currentVictim = nil
    end
end)