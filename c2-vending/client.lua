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
-- STATE
-- ===============================
local isUIOpen = false

-- ===============================
-- NUI HELPERS
-- ===============================
local function OpenVendingUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        items  = Config.VendingItems
    })
end

local function CloseVendingUI()
    if not isUIOpen then return end
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ===============================
-- NUI CALLBACKS
-- ===============================
RegisterNUICallback('close', function(_, cb)
    CloseVendingUI()
    cb('ok')
end)

RegisterNUICallback('buyItems', function(data, cb)
    if not data or not data.items or #data.items == 0 then
        cb('error')
        return
    end
    TriggerServerEvent('c2-vending:server:buyItems', data.items)
    cb('ok')
end)

-- ===============================
-- CLIENT EVENT: NOTIFY
-- ===============================
RegisterNetEvent('c2-vending:client:notify', function(msg, notifType)
    if ESX then
        ESX.ShowNotification(msg)
    elseif QBCore then
        QBCore.Functions.Notify(msg, notifType or 'error')
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end)

-- ===============================
-- OX_TARGET ZONES
-- ===============================
CreateThread(function()
    for i, machine in ipairs(Config.Machines) do
        exports.ox_target:addSphereZone({
            coords  = machine.coords,
            radius  = 1.5,
            options = {
                {
                    name     = 'c2_vending_use_' .. i,
                    label    = 'Use Vending Machine',
                    icon     = 'fas fa-shopping-cart',
                    onSelect = function()
                        OpenVendingUI()
                    end,
                }
            }
        })
    end
end)
