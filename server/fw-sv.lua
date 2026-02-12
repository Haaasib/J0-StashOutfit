local C, s = Config.FrameworkSettings.CoreName, function(r) return GetResourceState(r) == 'started' end
local isESX, isQB, Core = C == "es_extended", C:find("qb"), (C == "es_extended" and exports[C]:getSharedObject() or exports[C]:GetCoreObject())
local hasOx, hasQs, hasCodem, hasEsx = s('ox_inventory'), s('qs-inventory'), s('codem-inventory'), s('esx_inventoryhud')
local Cache = {
    ServerCallbacks = {},
}

FW = {}

FW.CreateCallback = function(name, cb)
    Cache.ServerCallbacks[name] = cb
end

FW.TriggerCallback = function(name, source, cb, ...)
    if not Cache.ServerCallbacks[name] then return end
    Cache.ServerCallbacks[name](source, cb, ...)
end

RegisterNetEvent('J0-FridgeWardobe:server:triggerCallback', function(name, ...)
    local src = source
    FW.TriggerCallback(name, src, function(...)
        TriggerClientEvent('J0-FridgeWardobe:client:triggerCallback', src, name, ...)
    end, ...)
end)

FW.GetPlayer = function(src)
    return isQB and Core.Functions.GetPlayer(src) or isESX and Core.GetPlayerFromId(src) or nil
end

FW.AddMoney = function(src, type, amt, desc)
    local player = FW.GetPlayer(tonumber(src) or 0)
    if not player then return end
    local amount = tonumber(amt) or 0
    if isQB and (type == "cash" or type == "bank") then
        player.Functions.AddMoney(type, amount, desc)
    elseif isESX then
        if type == "bank" then player.addAccountMoney("bank", amount, desc)
        elseif type == "cash" then player.addMoney(amount, desc) end
    end
end

FW.RemoveMoney = function(src, type, amt, desc)
    local player = FW.GetPlayer(src)
    if not player then return end
    if isQB then player.Functions.RemoveMoney(type, amt, desc)
    elseif isESX then
        if type == "bank" then player.removeAccountMoney("bank", amt, desc)
        elseif type == "cash" then player.removeMoney(amt, desc) end
    end
end

FW.GetPlayerMoney = function(src, type)
    local player = FW.GetPlayer(src)
    if not player then return 0 end
    if isQB then return player.PlayerData.money[type] or 0
    elseif isESX then
        local acc = player.getAccount(type == "cash" and "money" or "bank")
        return acc and acc.money or 0
    end
    return 0
end

FW.GetJobName = function(src)
    local player = FW.GetPlayer(src)
    if not player then return nil end
    if isQB then return player.PlayerData.job.name or nil
    elseif isESX then return player.job.name or nil end
    return nil
end

FW.GetPlayerCid = function(src)
    local player = FW.GetPlayer(src)
    if not player then return nil end
    return isQB and player.PlayerData.citizenid or isESX and player.getIdentifier and player.getIdentifier() or nil
end

FW.GetPlayerByCid = function(targetCid)
    for _, playerId in ipairs(GetPlayers()) do
        local playerSrc = tonumber(playerId)
        if playerSrc then
            local playerCid = FW.GetPlayerCid(playerSrc)
            if playerCid and tostring(playerCid) == tostring(targetCid) then
                return playerSrc
            end
        end
    end
    return nil
end

FW.PlayerName = function(src)
    local player = FW.GetPlayer(src)
    if not player then return "Unknown" end
    if isQB then return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname end
    return isESX and (player.getName() or player.firstname or "Unknown") or "Unknown"
end

FW.AddItem = function(src, name, amt, meta)
    local result
    if hasOx then result = exports.ox_inventory:AddItem(src, name, amt, meta)
    elseif hasQs then result = exports['qs-inventory']:AddItem(src, name, amt, meta)
    elseif hasCodem then result = exports["codem-inventory"]:AddItem(src, name, amt, meta)
    else
        local player = FW.GetPlayer(src)
        if player then
            if isQB then
                player.Functions.AddItem(name, amt, meta and false or nil, meta)
                result = true
            elseif isESX and hasEsx then result = player.addInventoryItem(name, amt) end
        end
    end
    return result
end

FW.RemoveItem = function(src, name, amt, meta)
    local result
    if hasOx then result = exports.ox_inventory:RemoveItem(src, name, amt, meta)
    elseif hasQs then result = exports['qs-inventory']:RemoveItem(src, name, amt, meta)
    elseif hasCodem then result = exports["codem-inventory"]:RemoveItem(src, name, amt, meta)
    else
        local player = FW.GetPlayer(src)
        if player then
            if isQB then player.Functions.RemoveItem(name, amt, meta)
            elseif isESX and hasEsx then result = player.removeInventoryItem(name, amt) end
        end
    end
    return result
end

FW.GetItemMetadata = function(src, name)
    if hasOx then
        local ok, inv = pcall(function() return exports.ox_inventory:GetInventory(src) end)
        if ok and inv and inv.items then
            for _, item in pairs(inv.items) do
                if item and item.name == name and item.count > 0 and item.metadata then return true, item.metadata end
            end
        end
        local ok2, item = pcall(function() return exports.ox_inventory:GetItem(src, name) end)
        if ok2 and item then
            if item.metadata then return true, item.metadata
            elseif type(item) == 'table' and item[1] and item[1].metadata then return true, item[1].metadata end
        end
    elseif hasQs then
        local item = exports['qs-inventory']:GetItem(src, name)
        if item and item.amount > 0 then return true, item.info or {} end
    elseif hasCodem then
        local item = exports["codem-inventory"]:GetItemByName(src, name)
        if item and item.amount > 0 then return true, item.metadata or {} end
    end
    local player = FW.GetPlayer(src)
    if player then
        if isQB then
            local item = player.Functions.GetItemByName(name)
            if item and item.amount > 0 then return true, item.info or item.metadata or {} end
        elseif isESX then
            local item = player.getInventoryItem(name)
            if item and item.count > 0 then return true, item.metadata or {} end
        end
    end
    return false, {}
end

FW.GetAllItems = function(src, name)
    local items = {}
    if hasOx then
        local ok, inv = pcall(function() return exports.ox_inventory:GetInventory(src) end)
        if ok and inv and inv.items then
            for _, item in pairs(inv.items) do
                if item and item.name == name and item.count > 0 then
                    table.insert(items, item.metadata or {})
                end
            end
        end
    elseif hasQs then
        local item = exports['qs-inventory']:GetItem(src, name)
        if item and item.amount > 0 then
            for i = 1, item.amount do
                table.insert(items, item.info or {})
            end
        end
    elseif hasCodem then
        local item = exports["codem-inventory"]:GetItemByName(src, name)
        if item and item.amount > 0 then
            for i = 1, item.amount do
                table.insert(items, item.metadata or {})
            end
        end
    else
        local player = FW.GetPlayer(src)
        if player then
            if isQB then
                local item = player.Functions.GetItemByName(name)
                if item and item.amount > 0 then
                    local itemsList = item.info or {}
                    if type(itemsList) == 'table' and itemsList[1] then
                        items = itemsList
                    else
                        for i = 1, item.amount do
                            table.insert(items, itemsList)
                        end
                    end
                end
            elseif isESX then
                local item = player.getInventoryItem(name)
                if item and item.count > 0 then
                    for i = 1, item.count do
                        table.insert(items, item.metadata or {})
                    end
                end
            end
        end
    end
    return items
end

FW.RegisterUsableItem = function(name)
    if hasQs then
        exports['qs-inventory']:CreateUsableItem(name, function(src, item)
            if name == 'burner_phone' then TriggerClientEvent('J0-J0-BlackMarket:client:openBurnerPhone', src) end
        end)
    elseif isQB then
        Core.Functions.CreateUseableItem(name, function(src, item)
            if name == 'burner_phone' then TriggerClientEvent('J0-J0-BlackMarket:client:openBurnerPhone', src) end
        end)
    elseif isESX then
        Core.RegisterUsableItem(name, function(src, item)
            if name == 'burner_phone' then TriggerClientEvent('J0-J0-BlackMarket:client:openBurnerPhone', src) end
        end)
    end
end
FW.RegisterStashItem = function(name)
    local cfg = Config.StashProps and Config.StashProps[name]
    if not cfg then return end
    if hasQs then
        exports['qs-inventory']:CreateUsableItem(name, function(src, item)
            TriggerClientEvent('J0-FridgeWardobe:client:startPlaceStash', src, name, cfg.stashName, cfg.slots, cfg.maxWeight)
        end)
    elseif isQB then
        Core.Functions.CreateUseableItem(name, function(src, item)
            TriggerClientEvent('J0-FridgeWardobe:client:startPlaceStash', src, name, cfg.stashName, cfg.slots, cfg.maxWeight)
        end)
    elseif isESX then
        Core.RegisterUsableItem(name, function(src, item)
            TriggerClientEvent('J0-FridgeWardobe:client:startPlaceStash', src, name, cfg.stashName, cfg.slots, cfg.maxWeight)
        end)
    end
end
FW.SendMail = function(subject, message, src)
    if not src then return end
    if Config.FrameworkSettings.EmailResource == 'lb-phone' then
        local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(src)
        exports["lb-phone"]:SendMessage(Config.BankingSettings.Details.PhoneNumber, phoneNumber, message, nil, nil, nil)
    elseif Config.FrameworkSettings.EmailResource == 'qb-phone' then
        TriggerClientEvent('qb-phone:client:sendNewMail', src, {
            sender = Config.Locales.fleeca_bank_name,
            subject = Config.BankingSettings.Details.PhoneNumber,
            message = message
        })
    elseif Config.FrameworkSettings.EmailResource == '17mov_Phone' then
        exports["17mov_Phone"]:Messages_SendMessageToSrc(src, message, Config.BankingSettings.Details.PhoneNumber)
    elseif Config.FrameworkSettings.EmailResource == 'npwd' then
        local player = FW.GetPlayer(src)
        if player then
            local phoneNumber = player.PlayerData.charinfo.phone or nil
            if phoneNumber then
                exports.npwd:emitMessage({
                    senderNumber = Config.BankingSettings.Details.PhoneNumber,
                    targetNumber = phoneNumber,
                    message = message,
                })
            end
        end
    else
        print('No email resource found, please set the EmailResource in the config.lua file to CUSTOM and add your own email resource')
    end
end

return FW
