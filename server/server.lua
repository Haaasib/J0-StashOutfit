local resName = GetCurrentResourceName()
local DataFile = 'server/data.json'
local Stashes = {}
local safe = function(fn) pcall(fn) end
local hasOx = function() return GetResourceState('ox_inventory') == 'started' end
local hasQs = function() return GetResourceState('qs-inventory') == 'started' end
local LoadResourceData = function()
    local raw = LoadResourceFile(resName, DataFile)
    if not raw or raw == '' then Stashes = {} return end
    local ok, data = pcall(json.decode, raw)
    Stashes = (ok and data and data.stashes) and data.stashes or {}
    for i = 1, #Stashes do
        if not Stashes[i].items then Stashes[i].items = {} end
        if not Stashes[i].allowedCids then Stashes[i].allowedCids = {} end
    end
end
local SaveResourceData = function()
    local data = json.encode({ stashes = Stashes })
    SaveResourceFile(resName, DataFile, data, #data)
end
local findStashById = function(stashId)
    for i = 1, #Stashes do
        local e = Stashes[i]
        if e.id == stashId or e.stashId == stashId then return e, i end
    end
    return nil, nil
end
local hasStashAccess = function(entry, cid)
    if entry.cid == cid then return true end
    local list = entry.allowedCids
    if not list then return false end
    for j = 1, #list do
        if tostring(list[j]) == tostring(cid) then return true end
    end
    return false
end
local getStashWeight = function(entry)
    local w = 0
    local items = entry.items or {}
    for j = 1, #items do
        local it = items[j]
        local iw = 0
        if hasOx() then
            local ok, dat = pcall(function() return exports.ox_inventory:Items(it.name) end)
            if ok and dat and dat.weight then iw = dat.weight * (it.count or 1) end
        end
        w = w + iw
    end
    return w
end
local getItemWeight = function(name)
    if hasOx() then
        local ok, dat = pcall(function() return exports.ox_inventory:Items(name) end)
        if ok and dat and dat.weight then return dat.weight end
    end
    return 0
end
local getPlayerItemsFiltered = function(src, allowedSet)
    local out = {}
    if hasOx() then
        local ok, inv = pcall(function() return exports.ox_inventory:GetInventory(src) end)
        if ok and inv and inv.items then
            for _, it in pairs(inv.items) do
                if it and it.name and it.count and it.count > 0 and allowedSet[it.name] then
                    local found
                    for k = 1, #out do
                        if out[k].name == it.name then out[k].count = out[k].count + it.count found = true break end
                    end
                    if not found then out[#out + 1] = { name = it.name, count = it.count } end
                end
            end
        end
    elseif hasQs() then
        local pItems = exports['qs-inventory']:GetInventory(src)
        if type(pItems) == 'table' then
            for _, it in pairs(pItems) do
                if it and it.name and it.amount and it.amount > 0 and allowedSet[it.name] then
                    local found
                    for k = 1, #out do
                        if out[k].name == it.name then out[k].count = out[k].count + it.amount found = true break end
                    end
                    if not found then out[#out + 1] = { name = it.name, count = it.amount } end
                end
            end
        end
    end
    return out
end
local sendStashListTo = function(src)
    if not src then return end
    TriggerClientEvent('J0-FridgeWardobe:client:receiveStashList', src, Stashes)
end
local discordCfg = Config.DiscordLog or {}
local discordEnabled = discordCfg.enabled and discordCfg.webhook and #(discordCfg.webhook or '') > 10
local DiscordLog = function(title, fields)
    if not discordEnabled then return end
    local f = {}
    if fields then for i = 1, #fields do f[#f + 1] = { name = fields[i].name or '', value = fields[i].value or '', inline = fields[i].inline ~= false } end end
    PerformHttpRequest(discordCfg.webhook, function() end, 'POST', json.encode({ embeds = { { title = title or 'Fridge/Wardrobe Stash', color = 3066993, fields = f } } }), { ['Content-Type'] = 'application/json' })
end
FW.CreateCallback('J0-FridgeWardobe:getStashList', function(src, cb)
    cb(Stashes)
end)
FW.CreateCallback('J0-FridgeWardobe:getStashMenuData', function(src, cb, stashId)
    local entry = findStashById(stashId)
    if not entry then cb(nil) return end
    local myCid = FW.GetPlayerCid(src)
    if not hasStashAccess(entry, myCid) then cb(nil) return end
    local cfg = Config.StashProps and Config.StashProps[entry.model]
    if not cfg then cb(nil) return end
    local allowedSet = {}
    if cfg.allowedItems then for j = 1, #cfg.allowedItems do allowedSet[cfg.allowedItems[j]] = true end end
    local playerItems = getPlayerItemsFiltered(src, allowedSet)
    local accessList = {}
    local list = entry.allowedCids or {}
    for j = 1, #list do
        local cid = list[j]
        local name = FW.PlayerName(FW.GetPlayerByCid(cid)) or tostring(cid)
        accessList[#accessList + 1] = { cid = cid, name = name }
    end
    cb({
        items = entry.items or {},
        allowedItems = cfg.allowedItems or {},
        playerItems = playerItems,
        isOwner = entry.cid == myCid,
        accessList = accessList,
        label = cfg.label or entry.id,
        slots = entry.slots or 40,
        maxWeight = entry.maxWeight or 80000
    })
end)
FW.CreateCallback('J0-FridgeWardobe:putItem', function(src, cb, stashId, itemName, count)
    local entry = findStashById(stashId)
    if not entry then cb(false) return end
    if not hasStashAccess(entry, FW.GetPlayerCid(src)) then cb(false) return end
    local cfg = Config.StashProps and Config.StashProps[entry.model]
    if not cfg then cb(false) return end
    local allowed = false
    if cfg.allowedItems then for j = 1, #cfg.allowedItems do if cfg.allowedItems[j] == itemName then allowed = true break end end end
    if not allowed then cb(false) return end
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then cb(false) return end
    if not FW.RemoveItem(src, itemName, count) then cb(false) return end
    local items = entry.items or {}
    local itemW = getItemWeight(itemName)
    local curW = getStashWeight(entry)
    if curW + itemW * count > (entry.maxWeight or 0) then FW.AddItem(src, itemName, count) cb(false) return end
    if #items >= (entry.slots or 40) then
        local stacked
        for k = 1, #items do
            if items[k].name == itemName then items[k].count = (items[k].count or 0) + count stacked = true break end
        end
        if not stacked then FW.AddItem(src, itemName, count) cb(false) return end
    else
        local stacked
        for k = 1, #items do
            if items[k].name == itemName then items[k].count = (items[k].count or 0) + count stacked = true break end
        end
        if not stacked then items[#items + 1] = { name = itemName, count = count, metadata = {} } end
    end
    entry.items = items
    SaveResourceData()
    DiscordLog('Stash – Item put', { { name = 'Player', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Stash ID', value = stashId }, { name = 'Item', value = itemName }, { name = 'Count', value = tostring(count) } })
    cb(true)
end)
FW.CreateCallback('J0-FridgeWardobe:takeItem', function(src, cb, stashId, itemName, count)
    local entry = findStashById(stashId)
    if not entry then cb(false) return end
    if not hasStashAccess(entry, FW.GetPlayerCid(src)) then cb(false) return end
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then cb(false) return end
    local items = entry.items or {}
    for j = 1, #items do
        if items[j].name == itemName then
            local have = items[j].count or 0
            if have < count then cb(false) return end
            if not FW.AddItem(src, itemName, count, items[j].metadata) then cb(false) return end
            items[j].count = have - count
            if items[j].count <= 0 then table.remove(items, j) end
            entry.items = items
            SaveResourceData()
            DiscordLog('Stash – Item taken', { { name = 'Player', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Stash ID', value = stashId }, { name = 'Item', value = itemName }, { name = 'Count', value = tostring(count) } })
            cb(true)
            return
        end
    end
    cb(false)
end)
FW.CreateCallback('J0-FridgeWardobe:pickupStash', function(src, cb, stashId)
    local entry, idx = findStashById(stashId)
    if not entry then cb(false) return end
    if entry.cid ~= FW.GetPlayerCid(src) then cb(false) return end
    local items = entry.items or {}
    for j = 1, #items do
        local it = items[j]
        local cnt = it.count or 0
        if cnt > 0 then FW.AddItem(src, it.name, cnt, it.metadata) end
    end
    table.remove(Stashes, idx)
    SaveResourceData()
    FW.AddItem(src, entry.model, 1)
    local itemList = {}
    for j = 1, #items do local it = items[j] itemList[#itemList + 1] = ('%s x%s'):format(it.name or '?', tostring(it.count or 0)) end
    DiscordLog('Stash – Picked up', { { name = 'Player', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Stash ID', value = stashId }, { name = 'Model', value = entry.model or '?' }, { name = 'Items returned', value = #itemList > 0 and table.concat(itemList, ', ') or 'None' } })
    TriggerClientEvent('J0-FridgeWardobe:client:removeStashProp', -1, stashId)
    cb(true)
end)
FW.CreateCallback('J0-FridgeWardobe:placeStash', function(src, cb, model, coords, heading)
    local cfg = Config.StashProps and Config.StashProps[model]
    if not cfg then cb(false) return end
    local minDist = Config.PlacementMinDistance or 2.0
    local vec = vector3(coords.x or 0, coords.y or 0, coords.z or 0)
    for i = 1, #Stashes do
        local e = Stashes[i]
        local ec = e.coords
        if ec and (ec.x or ec.y or ec.z) then
            local ev = vector3(ec.x or 0, ec.y or 0, ec.z or 0)
            if #(vec - ev) < minDist then cb(false, 'too_close') return end
        end
    end
    if not FW.RemoveItem(src, model, 1) then cb(false) return end
    local id = ('%s_%s_%s'):format(cfg.stashName, tostring(GetGameTimer()), tostring(src))
    local entry = { id = id, model = model, coords = coords, heading = heading, stashId = id, slots = cfg.slots, maxWeight = cfg.maxWeight, cid = FW.GetPlayerCid(src), allowedCids = {}, items = {} }
    Stashes[#Stashes + 1] = entry
    SaveResourceData()
    DiscordLog('Stash – Placed', { { name = 'Player', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Stash ID', value = id }, { name = 'Model', value = model or '?' }, { name = 'Coords', value = ('%.2f, %.2f, %.2f'):format(coords.x or 0, coords.y or 0, coords.z or 0) } })
    TriggerClientEvent('J0-FridgeWardobe:client:spawnStashProp', -1, entry)
    cb(true)
end)
FW.CreateCallback('J0-FridgeWardobe:grantAccess', function(src, cb, stashId, targetSrc)
    local entry = findStashById(stashId)
    if not entry then cb(false) return end
    if entry.cid ~= FW.GetPlayerCid(src) then cb(false) return end
    local targetCid = FW.GetPlayerCid(tonumber(targetSrc))
    if not targetCid or targetCid == entry.cid then cb(false) return end
    entry.allowedCids = entry.allowedCids or {}
    for j = 1, #entry.allowedCids do
        if tostring(entry.allowedCids[j]) == tostring(targetCid) then SaveResourceData() cb(true) return end
    end
    entry.allowedCids[#entry.allowedCids + 1] = targetCid
    SaveResourceData()
    DiscordLog('Stash – Access granted', { { name = 'Owner', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Target', value = ('%s (%s)'):format(FW.PlayerName(tonumber(targetSrc)) or '?', tostring(targetCid)) }, { name = 'Stash ID', value = stashId } })
    cb(true)
end)
FW.CreateCallback('J0-FridgeWardobe:revokeAccess', function(src, cb, stashId, targetCid)
    local entry = findStashById(stashId)
    if not entry then cb(false) return end
    if entry.cid ~= FW.GetPlayerCid(src) then cb(false) return end
    local list = entry.allowedCids or {}
    for j = #list, 1, -1 do
        if tostring(list[j]) == tostring(targetCid) then table.remove(list, j) break end
    end
    entry.allowedCids = list
    SaveResourceData()
    DiscordLog('Stash – Access revoked', { { name = 'Owner', value = ('%s (%s)'):format(FW.PlayerName(src) or '?', FW.GetPlayerCid(src) or '?') }, { name = 'Target CID', value = tostring(targetCid) }, { name = 'Stash ID', value = stashId } })
    cb(true)
end)
local CoreName = Config.FrameworkSettings.CoreName or ""
local isQB = CoreName:find("qb") and true or false
local isESX = CoreName == "es_extended"
if isQB then
    AddEventHandler('QBCore:Server:OnPlayerLoaded', function(Player, isNew, context)
        local src = type(Player) == "number" and Player or (Player and Player.PlayerData and Player.PlayerData.source)
        sendStashListTo(src)
    end)
end
if isESX then
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        sendStashListTo(playerId)
    end)
end
AddEventHandler('onResourceStart', function(res)
    if resName ~= res then return end
    LoadResourceData()
    CreateThread(function()
        Wait(2000)
        for _, pid in ipairs(GetPlayers()) do
            sendStashListTo(tonumber(pid))
        end
    end)
end)
for itemName in pairs(Config.StashProps or {}) do
    FW.RegisterStashItem(itemName)
end
