local C, s = Config.FrameworkSettings.CoreName, function(r) return GetResourceState(r) == 'started' end
local isESX, isQB, Core = C == "es_extended", C:find("qb"), (C == "es_extended" and exports[C]:getSharedObject() or exports[C]:GetCoreObject())
local hasOxTarget, hasQbTarget, hasInteract =  Config.FrameworkSettings.TargetSettings.resource == 'ox_target', Config.FrameworkSettings.TargetSettings.resource == 'qb-target', Config.FrameworkSettings.TargetSettings.resource == 'interact'
local confirmed
local heading
local Cache = {
    zones = {},
    peds = {},
    blips = {},
    targetZones = {},
    ServerCallbacks = {}
}
FW = {}

FW.TriggerCallback = function(name, cb, ...)
    Cache.ServerCallbacks[name] = cb
    TriggerServerEvent('J0-FridgeWardobe:server:triggerCallback', name, ...)
end

RegisterNetEvent('J0-FridgeWardobe:client:triggerCallback', function(name, ...)
    if Cache.ServerCallbacks[name] then
        Cache.ServerCallbacks[name](...)
        Cache.ServerCallbacks[name] = nil
    end
end)

FW.SendNuiMessage = function(action, data, bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = action,
        data = data
    })
end

FW.GetStreetName = function(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    if streetName and streetName ~= "" then
        if crossingName and crossingName ~= "" and crossingName ~= streetName then
            return streetName .. " / " .. crossingName
        end
        return streetName
    end
    return "Unknown Street"
end

FW.CreateBlip = function(coords, id, name, color, scale, shortRange)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, id)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    if shortRange then
        SetBlipAsShortRange(blip, true)
    end
    Cache.blips[id] = blip
    return blip
end

FW.RemoveBlip = function(blip)
    RemoveBlip(blip)
    Cache.blips[blip] = nil
end

FW.SendNotify = function(type, message)
   if isQB then
    Core.Functions.Notify(message, type, 5000)
   elseif isESX then
    Core.ShowNotification(message, type, 3000, "title here", "top-left")
   end
end

FW.CreatePed = function(model, coords, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z-1.0, heading, false, false)
    SetModelAsNoLongerNeeded(model)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedCanBeShotInVehicle(ped, false)
    SetEntityInvincible(ped, true)
    Cache.peds[ped] = ped
    return ped
end

FW.DeletePed = function(ped)
    if DoesEntityExist(ped) then
        DeletePed(ped)
    end
    Cache.peds[ped] = nil
end

FW.GetGtaTime = function()
    local hour = GetClockHours()
    local minute = GetClockMinutes()

    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    displayHour = displayHour == 0 and 12 or displayHour

    return {
        hour = displayHour,
        minute = minute,
        suffix = suffix,
        hour24 = hour,
        formatted = ("%02d:%02d %s"):format(displayHour, minute, suffix)
    }
end

FW.FixOptions = function(options)
    local fixedOptions = {}
    for k, v in pairs(options) do
        local action = v.onSelect or v.action
        local wrappedAction = action and function(data)
            local ent = type(data) == 'table' and data.entity or data
            local coords = type(data) == 'table' and data.coords or GetEntityCoords(ent)
            local args = v.args or {}
            local serverId = type(data) == 'table' and data.serverId or nil
            return action(ent, coords, args, serverId)
        end

        local option = {
            label = v.label,
            icon = v.icon,
            groups = v.groups or v.job,
            canInteract = v.canInteract,
            args = v.args
        }

        if hasOxTarget then
            option.onSelect = wrappedAction
            option.name = v.name or v.label
            option.serverEvent = v.serverEvent
            option.event = v.event
        elseif hasQbTarget then
            option.action = wrappedAction
            option.job = v.groups or v.job
            option.type = v.serverEvent and "server" or "client"
            option.event = v.serverEvent or v.event
        elseif hasInteract then
            option.action = wrappedAction
            option.name = v.name or v.label
        end
        fixedOptions[k] = option
    end
    return fixedOptions
end

local getDist = function(options)
    local d = 2.5
    for _, v in pairs(options) do
        if v.distance and v.distance > d then d = v.distance end
    end
    return d
end

FW.AddBoxZone = function(name, coords, size, heading, options)
    options = FW.FixOptions(options)
    local id = name
    if hasOxTarget then
        id = exports.ox_target:addBoxZone({
            coords = coords, size = size, rotation = heading,
            debug = Config.FrameworkSettings.TargetSettings.debug, options = options
        })
    elseif hasQbTarget then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name = name, heading = heading, debugPoly = Config.FrameworkSettings.TargetSettings.debug,
            minZ = coords.z - (size.z/2), maxZ = coords.z + (size.z/2)
        }, { options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddInteraction({
            id = name, coords = coords, options = options,
            distance = 8.0, interactDst = size.x
        })
    end
    table.insert(Cache.targetZones, { id = id, type = 'zone', creator = GetInvokingResource() })
    return id
end

FW.AddTargetModel = function(models, options)
    options = FW.FixOptions(options)
    local id = "model_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addModel(models, options)
    elseif hasQbTarget then
        exports['qb-target']:AddTargetModel(models, { options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddModelInteraction({ model = models, id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'model', target = models, creator = GetInvokingResource() })
end

FW.AddGlobalVehicle = function(options)
    options = FW.FixOptions(options)
    local id = "glob_veh_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addGlobalVehicle(options)
    elseif hasQbTarget then
        exports['qb-target']:AddGlobalVehicle({ options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddGlobalVehicleInteraction({ id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'vehicle', creator = GetInvokingResource() })
end

FW.AddGlobalPlayer = function(options)
    options = FW.FixOptions(options)
    local id = "glob_ply_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addGlobalPlayer(options)
    elseif hasQbTarget then
        exports['qb-target']:AddGlobalPlayer({ options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:addGlobalPlayerInteraction({ id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'player', creator = GetInvokingResource() })
end

FW.AddTargetEntity = function(entity, options)
    options = FW.FixOptions(options)
    if hasOxTarget then
        exports.ox_target:addLocalEntity(entity, options)
    elseif hasQbTarget then
        exports['qb-target']:AddTargetEntity(entity, { options = options, distance = getDist(options) })
    elseif hasInteract then
        local id = "entity_" .. tostring(entity)
        exports.interact:AddLocalEntityInteraction({
            entity = entity,
            id = id,
            options = options,
            distance = 10.0,
            interactDst = 4.0
        })
    end
    table.insert(Cache.targetZones, { id = entity, type = 'entity', creator = GetInvokingResource() })
end

FW.RemoveTargetEntity = function(entity)
    if hasOxTarget then
        exports.ox_target:removeLocalEntity(entity)
    elseif hasQbTarget then
        exports['qb-target']:RemoveTargetEntity(entity)
    elseif hasInteract then
        local id = "entity_" .. tostring(entity)
        exports.interact:RemoveLocalEntityInteraction(entity, id)
    end
end

FW.RemoveTarget = function(id, type)
    if type == 'entity' then FW.RemoveTargetEntity(id) return end
    if hasOxTarget then
        if type == 'zone' then exports.ox_target:removeZone(id) end
    elseif hasQbTarget then
        if type == 'zone' then
            pcall(function() exports['qb-target']:RemoveBoxZone(id) end)
        elseif type == 'model' then exports['qb-target']:RemoveTargetModel(id) end
    elseif hasInteract then
        if type == 'zone' then exports.interact:RemoveInteraction(id)
        elseif type == 'model' then exports.interact:RemoveModelInteraction(nil, id)
        elseif type == 'vehicle' then exports.interact:RemoveGlobalVehicleInteraction(id)
        elseif type == 'player' then exports.interact:RemoveGlobalPlayerInteraction(id) end
    end
end

RotationToDirection = function(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

DrawPropAxes = function(prop)
    local propForward, propRight, propUp, propCoords = GetEntityMatrix(prop)

    local propXAxisEnd = propCoords + propRight * 1.0
    local propYAxisEnd = propCoords + propForward * 1.0
    local propZAxisEnd = propCoords + propUp * 1.0

    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propXAxisEnd.x, propXAxisEnd.y, propXAxisEnd.z, 255, 0, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propYAxisEnd.x, propYAxisEnd.y, propYAxisEnd.z, 0, 255, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propZAxisEnd.x, propZAxisEnd.y, propZAxisEnd.z, 0, 0, 255, 255)
end

RayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

FW.PlaceProp = function(prop, onConfirm)
    local hash = type(prop) == 'string' and joaat(prop) or prop
    local heading = 0.0
    local confirmed = false
    local moveZ = 0.0
    local topDown = false
    local maxDist = 5.0
    local ped = PlayerPedId()
    local hit, coords, entity
    while not hit do
        hit, coords, entity = RayCastGamePlayCamera(1000.0)
        Wait(0)
    end
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, false, true)
    FreezeEntityPosition(ped, true)
    FW.SendNotify('primary', L.placement_hint)
    CreateThread(function()
        while not confirmed do
            hit, coords, entity = RayCastGamePlayCamera(1000.0)
            local pcoords = GetEntityCoords(ped)
            local vec = coords - pcoords
            local len = #vec
            if len > maxDist then vec = vec * (maxDist / len) end
            coords = pcoords + vec
            coords = vector3(coords.x, coords.y, coords.z + moveZ)
            local vec2 = coords - pcoords
            if #vec2 > maxDist then
                vec2 = vec2 * (maxDist / #vec2)
                coords = pcoords + vec2
            end
            SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z, false, false, false, true)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
            SetEntityAlpha(obj, 100, false)
            DrawPropAxes(obj)
            Wait(0)
            if IsControlPressed(0, 174) then heading = heading + 1.0
            elseif IsControlPressed(0, 175) then heading = heading - 1.0 end
            if IsControlPressed(0, 241) then moveZ = moveZ + 0.05
            elseif IsControlPressed(0, 242) then moveZ = moveZ - 0.05 end
            if heading > 360.0 then heading = 0.0 elseif heading < 0.0 then heading = 360.0 end
            SetEntityHeading(obj, heading)
            if IsControlJustPressed(0, 44) then
                topDown = not topDown
                SetGameplayCamRelativePitch(topDown and -80.0 or 0.0, 1.0)
            end
            if IsControlJustPressed(0, 38) then
                confirmed = true
                FreezeEntityPosition(ped, false)
                SetGameplayCamRelativePitch(0.0, 1.0)
                SetEntityAlpha(obj, 255, false)
                SetEntityCollision(obj, true, true)
                if onConfirm then onConfirm(obj, GetEntityCoords(obj), GetEntityHeading(obj)) end
            elseif IsControlJustPressed(0, 47) or IsControlJustPressed(0, 200) then
                confirmed = true
                FreezeEntityPosition(ped, false)
                SetGameplayCamRelativePitch(0.0, 1.0)
                if DoesEntityExist(obj) then DeleteEntity(obj) end
                if onConfirm then onConfirm(nil, nil, nil) end
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    for k, v in pairs(Cache.zones) do
        if v and v.destroy then v:destroy() end
    end
    for k, v in pairs(Cache.peds) do
        if v then FW.DeletePed(v) end
    end
    for k, v in pairs(Cache.blips) do
        if v then FW.RemoveBlip(v) end
    end
    Cache.zones = {}
    Cache.peds = {}
    Cache.blips = {}
    for _, v in pairs(Cache.targetZones) do
        FW.RemoveTarget(v.id, v.type)
    end
end)

return FW

