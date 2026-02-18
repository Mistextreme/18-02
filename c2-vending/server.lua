-- ===============================
-- FRAMEWORK DETECTION
-- ===============================
local ESX = nil
local QBCore = nil

if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- ===============================
-- COOLDOWN TRACKER
-- ===============================
local cooldowns = {}

-- ===============================
-- HELPERS
-- ===============================

--- Validates items against Config.VendingItems and returns total cost.
--- Returns nil if any item is invalid or tampered.
local function ValidateAndTotal(items)
    local total = 0
    for _, entry in ipairs(items) do
        local found = false
        for _, cfg in ipairs(Config.VendingItems) do
            if cfg.item == entry.item then
                -- Use server-side price only — never trust client price
                total = total + (cfg.price * entry.quantity)
                found = true
                break
            end
        end
        if not found then
            return nil, ('Invalid item: %s'):format(tostring(entry.item))
        end
        if type(entry.quantity) ~= 'number' or entry.quantity < 1 or math.floor(entry.quantity) ~= entry.quantity then
            return nil, ('Invalid quantity for item: %s'):format(tostring(entry.item))
        end
    end
    return total
end

--- Gives items to a player depending on active framework/inventory.
local function GiveItems(src, items, xPlayer, qbPlayer)
    for _, entry in ipairs(items) do
        local itemName = entry.item
        local qty      = entry.quantity

        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:AddItem(src, itemName, qty)

        elseif xPlayer then
            for i = 1, qty do
                xPlayer.addInventoryItem(itemName, 1)
            end

        elseif qbPlayer then
            qbPlayer.Functions.AddItem(itemName, qty)
            TriggerClientEvent('inventory:client:ItemBox', src,
                QBCore.Shared.Items[itemName], 'add', qty)
        end
    end
end

-- ===============================
-- BUY ITEMS EVENT
-- ===============================
RegisterNetEvent('c2-vending:server:buyItems', function(items)
    local src = source

    -- Cooldown check
    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < Config.Cooldown then
        return
    end
    cooldowns[src] = now

    -- Basic input guard
    if type(items) ~= 'table' or #items == 0 then return end

    -- Validate items & compute server-authoritative total
    local total, err = ValidateAndTotal(items)
    if not total then
        print(('[c2-vending] Purchase blocked for src %d: %s'):format(src, err))
        TriggerClientEvent('c2-vending:client:notify', src, 'Purchase failed.', 'error')
        return
    end

    -- ==============================
    -- ESX
    -- ==============================
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end

        local account = xPlayer.getAccount(Config.Account)
        if not account or account.money < total then
            TriggerClientEvent('c2-vending:client:notify', src, 'Not enough money!', 'error')
            return
        end

        xPlayer.removeAccountMoney(Config.Account, total)
        GiveItems(src, items, xPlayer, nil)

    -- ==============================
    -- QBCORE
    -- ==============================
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local moneyType    = Config.Account == 'cash' and 'cash' or 'bank'
        local playerMoney  = Player.PlayerData.money[moneyType]

        if playerMoney < total then
            TriggerClientEvent('c2-vending:client:notify', src, 'Not enough money!', 'error')
            return
        end

        Player.Functions.RemoveMoney(moneyType, total, 'vending-machine-purchase')
        GiveItems(src, items, nil, Player)

    -- ==============================
    -- NO FRAMEWORK (ox_inventory only)
    -- ==============================
    else
        if GetResourceState('ox_inventory') ~= 'started' then
            print('[c2-vending] No supported framework or inventory found.')
            return
        end
        -- No money deduction possible without a framework; give items directly.
        GiveItems(src, items, nil, nil)
    end
end)

-- ===============================
-- CLEANUP ON DROP
-- ===============================
AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
