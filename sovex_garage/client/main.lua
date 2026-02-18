-- =====================================================
-- CLIENT  –  sovex_garage
-- =====================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- =====================================================
-- STATE
-- =====================================================
local isUIOpen         = false
local currentGarage    = nil   -- Config.Garages entry currently open
local currentVehicles  = {}    -- list returned by server for this garage
local lastInteract     = 0

-- =====================================================
-- HELPERS
-- =====================================================

local function DebugPrint(...)
    if Config.Debug then
        print('[sovex_garage][CLIENT]', ...)
    end
end

local function Notify(msg, ntype)
    ntype = ntype or 'error'
    if Config.NotifyStyle == 'ox' then
        lib.notify({ title = 'Garage', description = msg, type = ntype })
    else
        QBCore.Functions.Notify(msg, ntype)
    end
end

local function NuiPost(endpoint, data)
    return fetch(('https://%s/%s'):format(GetParentResourceName(), endpoint), {
        method  = 'POST',
        headers = { ['Content-Type'] = 'application/json' },
        body    = json.encode(data or {}),
    })
end

local function CloseUI()
    if not isUIOpen then return end
    isUIOpen      = false
    currentGarage = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    DebugPrint('UI closed')
end

-- =====================================================
-- OPEN GARAGE
-- =====================================================

local function OpenGarage(garage)
    local now = GetGameTimer()
    if (now - lastInteract) < Config.Cooldown then
        Notify(L('cooldownActive'), 'error')
        return
    end
    lastInteract = now

    DebugPrint('Opening garage:', garage.name)

    QBCore.Functions.TriggerCallback('sovex_garage:cb:getVehicles', function(vehicles)
        if not vehicles then
            Notify(L('invalidGarage'), 'error')
            return
        end

        if #vehicles == 0 then
            Notify(L('noVehicles'), 'primary')
            return
        end

        currentGarage   = garage
        currentVehicles = vehicles
        isUIOpen        = true

        -- Send theme + locale strings first
        SendNUIMessage({
            action = 'config',
            theme  = Config.Theme,
            texts  = GetLocaleTable(),
        })

        -- Build NUI vehicle list
        local nuiVehicles = {}
        for _, v in ipairs(vehicles) do
            local damage = v.sovex_damage and json.decode(v.sovex_damage) or {}
            nuiVehicles[#nuiVehicles + 1] = {
                plate  = v.plate,
                name   = QBCore.Shared.Vehicles[v.vehicle] and
                             QBCore.Shared.Vehicles[v.vehicle].name or v.vehicle,
                stored = v.state == 0,  -- 0 = stored, 1 = out
                fuel   = damage.fuel   or Config.DamageDefaults.fuel,
                engine = math.floor(((damage.engine or Config.DamageDefaults.engine) / 1000) * 100),
                body   = math.floor(((damage.body   or Config.DamageDefaults.body)   / 1000) * 100),
            }
        end

        SendNUIMessage({
            action   = 'open',
            title    = garage.label or 'GARAGE',
            vehicles = nuiVehicles,
        })

        SetNuiFocus(true, true)
        DebugPrint('Opened garage with', #vehicles, 'vehicles')
    end, garage.name)
end

-- =====================================================
-- NUI CALLBACKS
-- =====================================================

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('selectVehicle', function(data, cb)
    -- Index is used locally; nothing extra to do server-side on selection.
    DebugPrint('Vehicle selected at index:', data.index)
    cb('ok')
end)

RegisterNUICallback('takeVehicle', function(data, cb)
    cb('ok')  -- acknowledge immediately so NUI doesn't hang

    if not currentGarage then
        CloseUI()
        return
    end

    local idx     = (data.index or 0) + 1   -- Lua 1-based
    local vehicle = currentVehicles[idx]

    if not vehicle then
        Notify(L('vehicleNotOwned'), 'error')
        CloseUI()
        return
    end

    if vehicle.state ~= 0 then
        Notify(L('vehicleOutside'), 'error')
        CloseUI()
        return
    end

    DebugPrint('Taking vehicle:', vehicle.plate)

    TriggerServerEvent('sovex_garage:sv:takeVehicle', {
        plate       = vehicle.plate,
        garageName  = currentGarage.name,
        spawnCoords = currentGarage.spawn,
    })

    CloseUI()
end)

-- =====================================================
-- CLIENT EVENTS  (from server)
-- =====================================================

RegisterNetEvent('sovex_garage:cl:spawnVehicle', function(vehicleData)
    DebugPrint('Spawning vehicle:', vehicleData.model, vehicleData.plate)

    local spawnPoint = vehicleData.spawnCoords
    local coords     = vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)
    local heading    = spawnPoint.w or spawnPoint.heading or 0.0

    local modelHash = GetHashKey(vehicleData.model)
    lib.requestModel(modelHash, 10000)

    local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)

    -- Wait for vehicle to be created
    local timeout = 5000
    while not DoesEntityExist(veh) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end

    if not DoesEntityExist(veh) then
        Notify(L('vehicleSpawnFailed'), 'error')
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    -- Apply plate
    SetVehicleNumberPlateText(veh, vehicleData.plate)

    -- Apply mods/properties if stored
    if vehicleData.mods then
        local props = vehicleData.mods
        QBCore.Functions.SetVehicleProperties(veh, props)
    end

    -- Apply damage
    if vehicleData.damage then
        local dmg = vehicleData.damage
        SetVehicleEngineHealth(veh, dmg.engine or Config.DamageDefaults.engine)
        SetVehicleBodyHealth(veh,   dmg.body   or Config.DamageDefaults.body)
        SetVehicleFuelLevel(veh,    dmg.fuel   or Config.DamageDefaults.fuel)
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(modelHash)

    -- Put player in vehicle
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)

    Notify(L('vehicleTaken'), 'success')
    DebugPrint('Vehicle spawned successfully:', vehicleData.plate)
end)

RegisterNetEvent('sovex_garage:cl:notify', function(key, ntype)
    Notify(L(key), ntype or 'error')
end)

-- =====================================================
-- OX_TARGET ZONE REGISTRATION
-- =====================================================

CreateThread(function()
    -- Wait for garages to be loaded from server (DB) or use Config.Garages directly
    if Config.UseDatabase then
        -- Request garage list from server
        QBCore.Functions.TriggerCallback('sovex_garage:cb:getGarages', function(garages)
            if not garages or #garages == 0 then
                DebugPrint('No garages returned from server, using Config.Garages fallback')
                garages = Config.Garages
            end
            RegisterGarageZones(garages)
        end)
    else
        RegisterGarageZones(Config.Garages)
    end
end)

function RegisterGarageZones(garages)
    for i, garage in ipairs(garages) do
        local coords = type(garage.coords) == 'table'
            and vector3(garage.coords.x, garage.coords.y, garage.coords.z)
            or  garage.coords

        exports.ox_target:addSphereZone({
            coords  = coords,
            radius  = Config.TargetDistance,
            options = {
                {
                    name     = ('sovex_garage_zone_%d'):format(i),
                    icon     = Config.TargetIcon,
                    label    = garage.label or Config.TargetLabel,
                    onSelect = function()
                        OpenGarage(garage)
                    end,
                },
            },
        })

        DebugPrint(('Registered zone for garage: %s at %s'):format(
            garage.name,
            tostring(coords)
        ))
    end
end

-- =====================================================
-- ESC KEY FALLBACK
-- =====================================================

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen and IsControlJustPressed(0, 200) then -- INPUT_FRONTEND_CANCEL
            CloseUI()
        end
    end
end)
