local StashCache = { 
    props = {}
}

local getModelHash = function(m)
    local h = type(m) == 'string' and GetHashKey(m) or m
    return h
end

RegisterNetEvent('J0-FridgeWardobe:client:startPlaceStash', function(model, stashName, slots, maxWeight)
    RequestModel(type(model) == 'string' and getModelHash(model) or model)
    local hash = getModelHash(model)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do Wait(100) timeout = timeout + 1 end
    if not HasModelLoaded(hash) then return end
    SetModelAsNoLongerNeeded(hash)
    FW.PlaceProp(model, function(prop, coords, heading)
        if not prop or not coords then return end
        DeleteEntity(prop)
        FW.TriggerCallback('J0-FridgeWardobe:placeStash', function(...)
            local success, reason = ...
            if not success then
                local msg = (reason == 'too_close' and (L.stash_too_close or 'Too close to another stash')) or (L.could_not_place or 'Could not place stash')
                FW.SendNotify('error', msg)
            end
        end, model, { x = coords.x, y = coords.y, z = coords.z }, heading or 0)
    end)
end)

local getItemImageUrl = function(itemName)
    if not itemName or itemName == '' then return nil end
    if GetResourceState('ox_inventory') == 'started' then
        return ('nui://ox_inventory/web/images/%s.png'):format(itemName)
    end
    if GetResourceState('qs-inventory') == 'started' then
        return ('nui://qs-inventory/html/images/%s.png'):format(itemName)
    end
    if GetResourceState('qb-inventory') == 'started' then
        return ('nui://qb-inventory/html/images/%s.png'):format(itemName)
    end
    return nil
end

local showPutMenu = function(stashId)
    FW.TriggerCallback('J0-FridgeWardobe:getStashMenuData', function(data)
        if not data then return end
        local putOpts = {}
        for i = 1, #data.playerItems do
            local it = data.playerItems[i]
            putOpts[#putOpts + 1] = {
                title = it.name .. ' x' .. tostring(it.count),
                icon = getItemImageUrl(it.name) or 'chevron-right',
                image = getItemImageUrl(it.name),
                onSelect = function()
                    local input = lib.inputDialog('Put ' .. it.name, { { type = 'number', label = L.count or 'Count', min = 1, max = it.count, default = 1 } })
                    if input and input[1] then
                        FW.TriggerCallback('J0-FridgeWardobe:putItem', function(ok)
                            if ok then showPutMenu(stashId) else FW.SendNotify('error', L.could_not_put or 'Could not put item') end
                        end, stashId, it.name, input[1])
                    end
                end
            }
        end
        if #putOpts == 0 then putOpts[#putOpts + 1] = { title = L.no_allowed_items or 'No allowed items', icon = 'xmark', disabled = true } end
        lib.registerContext({ id = 'stash_put', title = L.put_item or 'Put Item', options = putOpts })
        lib.showContext('stash_put')
    end, stashId)
end

local showTakeMenu = function(stashId)
    FW.TriggerCallback('J0-FridgeWardobe:getStashMenuData', function(data)
        if not data then return end
        local takeOpts = {}
        for i = 1, #data.items do
            local it = data.items[i]
            local cnt = it.count or 0
            takeOpts[#takeOpts + 1] = {
                title = it.name .. ' x' .. tostring(cnt),
                icon = getItemImageUrl(it.name) or 'chevron-right',
                image = getItemImageUrl(it.name),
                onSelect = function()
                    local input = lib.inputDialog('Take ' .. it.name, { { type = 'number', label = L.count or 'Count', min = 1, max = cnt, default = 1 } })
                    if input and input[1] then
                        FW.TriggerCallback('J0-FridgeWardobe:takeItem', function(ok)
                            if ok then showTakeMenu(stashId) else FW.SendNotify('error', L.could_not_take or 'Could not take item') end
                        end, stashId, it.name, input[1])
                    end
                end
            }
        end
        if #takeOpts == 0 then takeOpts[#takeOpts + 1] = { title = L.empty or 'Empty', icon = 'box-open', disabled = true } end
        lib.registerContext({ id = 'stash_take', title = L.take_item or 'Take Item', options = takeOpts })
        lib.showContext('stash_take')
    end, stashId)
end

local showAccessMenu = function(stashId)
    FW.TriggerCallback('J0-FridgeWardobe:getStashMenuData', function(data)
        if not data then return end
        local accessList = data.accessList or {}
        local revokeOpts = {}
        for i = 1, #accessList do
            local a = accessList[i]
            revokeOpts[#revokeOpts + 1] = {
                title = a.name or tostring(a.cid),
                description = L.revoke or 'Revoke',
                icon = 'user-minus',
                onSelect = function()
                    FW.TriggerCallback('J0-FridgeWardobe:revokeAccess', function(ok)
                        if ok then FW.SendNotify('success', L.access_revoked or 'Access revoked') showAccessMenu(stashId) else FW.SendNotify('error', L.could_not_place or 'Failed') end
                    end, stashId, a.cid)
                end
            }
        end
        if #revokeOpts == 0 then revokeOpts[#revokeOpts + 1] = { title = L.no_access_list or 'No one has access', icon = 'users', disabled = true } end
        lib.registerContext({ id = 'stash_access', title = L.manage_access or 'Manage Access', options = revokeOpts })
        lib.showContext('stash_access')
    end, stashId)
end

local spawnStashProp = function(entry)
    local id, model, coords, heading = entry.id, entry.model, entry.coords, entry.heading
    if StashCache.props[id] and DoesEntityExist(StashCache.props[id]) then return end
    local c = coords
    local vec = vector3(c.x, c.y, c.z)
    local hash = getModelHash(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(hash) then return end
    local obj = CreateObject(hash, vec.x, vec.y, vec.z, false, false, false)
    SetEntityHeading(obj, heading or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)
    StashCache.props[id] = obj
    local sid = entry.stashId
    local propCfg = Config.StashProps and Config.StashProps[entry.model]
    local isWardrobe = propCfg and propCfg.isWardrobe
    local targetOpts
    if isWardrobe then
        targetOpts = {
            { label = L and L.get_outfit or 'Get Outfit', icon = 'fas fa-tshirt', onSelect = function() if Config.LoadOutfitEvent then Config.LoadOutfitEvent() end end },
            { label = L and L.put_item or 'Put Item', icon = 'fas fa-box', args = { sid }, onSelect = function(ent, pos, args) showPutMenu(args[1]) end },
            { label = L and L.take_item or 'Take Item', icon = 'fas fa-hand-holding', args = { sid }, onSelect = function(ent, pos, args) showTakeMenu(args[1]) end },
            { label = L and L.pickup or 'Pickup', icon = 'fas fa-hand-holding', args = { sid }, onSelect = function(ent, pos, args)
                FW.TriggerCallback('J0-FridgeWardobe:pickupStash', function(ok)
                    if ok then FW.SendNotify('success', L and L.stash_picked_up or 'Stash picked up') else FW.SendNotify('error', L and L.not_owner or 'You do not own this stash') end
                end, args[1])
            end },
            { label = L and L.give_access or 'Give Access', icon = 'fas fa-user-plus', args = { sid }, onSelect = function(ent, pos, args)
                local input = lib.inputDialog(L and L.give_access or 'Give Access', { { type = 'number', label = L and L.player_id or 'Player ID', min = 1, description = L and L.give_access_prompt } })
                if input and input[1] then
                    FW.TriggerCallback('J0-FridgeWardobe:grantAccess', function(ok)
                        if ok then FW.SendNotify('success', L and L.access_granted or 'Access granted') else FW.SendNotify('error', L and L.could_not_place or 'Failed') end
                    end, args[1], input[1])
                end
            end },
            { label = L and L.manage_access or 'Manage Access', icon = 'fas fa-users', args = { sid }, onSelect = function(ent, pos, args) showAccessMenu(args[1]) end }
        }
    else
        targetOpts = {
            { label = L and L.put_item or 'Put Item', icon = 'fas fa-box', args = { sid }, onSelect = function(ent, pos, args) showPutMenu(args[1]) end },
            { label = L and L.take_item or 'Take Item', icon = 'fas fa-hand-holding', args = { sid }, onSelect = function(ent, pos, args) showTakeMenu(args[1]) end },
            { label = L and L.pickup or 'Pickup', icon = 'fas fa-hand-holding', args = { sid }, onSelect = function(ent, pos, args)
                FW.TriggerCallback('J0-FridgeWardobe:pickupStash', function(ok)
                    if ok then FW.SendNotify('success', L and L.stash_picked_up or 'Stash picked up') else FW.SendNotify('error', L and L.not_owner or 'You do not own this stash') end
                end, args[1])
            end },
            { label = L and L.give_access or 'Give Access', icon = 'fas fa-user-plus', args = { sid }, onSelect = function(ent, pos, args)
                local input = lib.inputDialog(L and L.give_access or 'Give Access', { { type = 'number', label = L and L.player_id or 'Player ID', min = 1, description = L and L.give_access_prompt } })
                if input and input[1] then
                    FW.TriggerCallback('J0-FridgeWardobe:grantAccess', function(ok)
                        if ok then FW.SendNotify('success', L and L.access_granted or 'Access granted') else FW.SendNotify('error', L and L.could_not_place or 'Failed') end
                    end, args[1], input[1])
                end
            end },
            { label = L and L.manage_access or 'Manage Access', icon = 'fas fa-users', args = { sid }, onSelect = function(ent, pos, args) showAccessMenu(args[1]) end }
        }
    end
    FW.AddTargetEntity(obj, targetOpts)
end

RegisterNetEvent('J0-FridgeWardobe:client:spawnStashProp', function(entry)
    if not entry or not entry.id then return end
    spawnStashProp(entry)
end)

RegisterNetEvent('J0-FridgeWardobe:client:removeStashProp', function(stashId)
    if not stashId then return end
    local obj = StashCache.props[stashId]
    if obj and DoesEntityExist(obj) then
        FW.RemoveTargetEntity(obj)
        DeleteEntity(obj)
        StashCache.props[stashId] = nil
    end
end)

RegisterNetEvent('J0-FridgeWardobe:client:receiveStashList', function(list)
    if not list or type(list) ~= 'table' then return end
    for i = 1, #list do
        spawnStashProp(list[i])
    end
end)

CreateThread(function()
    FW.TriggerCallback('J0-FridgeWardobe:getStashList', function(list)
        if not list or type(list) ~= 'table' then return end
        for i = 1, #list do
            spawnStashProp(list[i])
        end
    end)
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    for _, ent in pairs(StashCache.props) do
        if DoesEntityExist(ent) then
            FW.RemoveTargetEntity(ent)
            DeleteEntity(ent)
        end
    end
    StashCache.props = {}
end)

RegisterCommand("pedtest", function()
    SetFrontendActive(false)
    Wait(1000)
    ReplaceHudColourWithRgba(117, R, G, B, A);
    SetFrontendActive(true)
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY"), false, -1)

    Wait(100)
    N_0x98215325a695e78a(false)

    local playerped = ClonePed(PlayerPedId(), GetEntityHeading(PlayerPedId()), false, false)
    SetEntityVisible(playerped, false, false)
    Wait(200)
    GivePedToPauseMenu(playerped, 1)
    SetPauseMenuPedLighting(true)
    SetPauseMenuPedSleepState(true)
 ---- this is for close 
    Wait(1000)
    SetFrontendActive(false) 
end)