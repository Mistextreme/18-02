-- =====================================================
-- SERVER  –  sovex_garage
-- =====================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- =====================================================
-- STATE
-- =====================================================
local loadedGarages = {}   -- name → garage table (from DB or Config)
local cooldowns     = {}   -- src → GetGameTimer()

-- =====================================================
-- HELPERS
-- =====================================================

local function DebugPrint(...)
    if Config.Debug then
        print('[sovex_garage][SERVER]', ...)
    end
end

local function IsOnCooldown(src)
    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < Config.Cooldown then
        return true
    end
    cooldowns[src] = now
    return false
end

local function GetGarage(name)
    return loadedGarages[name]
end

--- Checks whether `src` is allowed to access the given garage based on access_type.
---@param src number
---@param garage table
---@return boolean
local function PlayerCanAccess(src, garage)
    local atype = garage.access_type or 'public'
    if atype == 'public' then return true end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    if atype == 'job' then
        local jobName = Player.PlayerData.job and Player.PlayerData.job.name
        return jobName == garage.access_data
    end

    if atype == 'gang' then
        local gangName = Player.PlayerData.gang and Player.PlayerData.gang.name
        return gangName == garage.access_data
    end

    if atype == 'private' then
        -- access_data is expected to be a JSON array of citizenids
        local allowed = json.decode(garage.access_data or '[]') or {}
        local cid     = Player.PlayerData.citizenid
        for _, id in ipairs(allowed) do
            if id == cid then return true end
        end
        return false
    end

    return false
end

-- =====================================================
-- GARAGE LOADING
-- =====================================================

local function ParseCoords(raw)
    if not raw then return nil end
    local t = type(raw) == 'table' and raw or json.decode(raw)
    if not t then return nil end
    return { x = t.x, y = t.y, z = t.z, w = t.w or t.heading or 0.0 }
end

local function LoadGaragesFromDB()
    local rows = MySQL.query.await('SELECT * FROM sovex_garages')
    if not rows then
        DebugPrint('No rows returned from sovex_garages')
        return
    end

    for _, row in ipairs(rows) do
        local garage = {
            name        = row.name,
            type        = row.type,
            label       = row.label,
            access_type = row.access_type or 'public',
            access_data = row.access_data,
            coords      = ParseCoords(row.coords),
            spawn       = ParseCoords(row.spawn),
        }
        loadedGarages[garage.name] = garage
        DebugPrint('Loaded garage from DB:', garage.name)
    end
end

local function LoadGaragesFromConfig()
    for _, garage in ipairs(Config.Garages) do
        local g = {
            name        = garage.name,
            type        = garage.type        or 'public',
            label       = garage.label,
            access_type = garage.access_type or 'public',
            access_data = garage.access_data,
            coords      = garage.coords,
            spawn       = type(garage.spawn) == 'table' and garage.spawn or nil,
        }
        loadedGarages[g.name] = g
        DebugPrint('Loaded garage from Config:', g.name)
    end
end

--- Seeds Config.Garages into the DB if they don't already exist.
local function SeedGaragesToDB()
    for _, garage in ipairs(Config.Garages) do
        local existing = MySQL.scalar.await(
            'SELECT id FROM sovex_garages WHERE name = ?',
            { garage.name }
        )
        if not existing then
            local spawnJson  = json.encode(garage.spawn or {})
            local coordsJson = type(garage.coords) == 'vector3'
                and json.encode({ x = garage.coords.x, y = garage.coords.y, z = garage.coords.z })
                or  json.encode(garage.coords)

            MySQL.insert.await(
                [[INSERT INTO sovex_garages
                    (name, type, label, coords, spawn, access_type, access_data)
                  VALUES (?, ?, ?, ?, ?, ?, ?)]],
                {
                    garage.name,
                    garage.type        or 'public',
                    garage.label,
                    coordsJson,
                    spawnJson,
                    garage.access_type or 'public',
                    garage.access_data or nil,
                }
            )
            DebugPrint('Seeded garage to DB:', garage.name)
        end
    end
end

-- =====================================================
-- STARTUP
-- =====================================================

CreateThread(function()
    Wait(1000) -- allow oxmysql to connect

    if Config.UseDatabase then
        SeedGaragesToDB()
        LoadGaragesFromDB()
    else
        LoadGaragesFromConfig()
    end

    local count = 0
    for _ in pairs(loadedGarages) do count = count + 1 end
    DebugPrint(('Loaded %d garage(s)'):format(count))
end)

-- =====================================================
-- CALLBACK: GET GARAGES (for client zone registration)
-- =====================================================

lib.callback.register('sovex_garage:cb:getGarages', function(src)
    local list = {}
    for _, g in pairs(loadedGarages) do
        list[#list + 1] = {
            name        = g.name,
            label       = g.label,
            access_type = g.access_type,
            access_data = g.access_data,
            coords      = g.coords,
            spawn       = g.spawn,
        }
    end
    return list
end)

-- =====================================================
-- CALLBACK: GET VEHICLES FOR A GARAGE
-- =====================================================

lib.callback.register('sovex_garage:cb:getVehicles', function(src, garageName)
    if IsOnCooldown(src) then return {} end

    local garage = GetGarage(garageName)
    if not garage then
        DebugPrint('Garage not found:', garageName)
        return nil
    end

    if not PlayerCanAccess(src, garage) then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'accessDenied', 'error')
        return {}
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end

    local citizenid = Player.PlayerData.citizenid

    -- state = 0 means stored in garage; garage column stores the garage name
    local rows = MySQL.query.await(
        [[SELECT plate, vehicle, state, garage, mods, fuel, sovex_damage
          FROM player_vehicles
          WHERE citizenid = ? AND garage = ?
          ORDER BY plate ASC]],
        { citizenid, garageName }
    )

    DebugPrint(('getVehicles: %d rows for %s in %s'):format(
        rows and #rows or 0, citizenid, garageName
    ))

    return rows or {}
end)

-- =====================================================
-- EVENT: TAKE VEHICLE
-- =====================================================

RegisterNetEvent('sovex_garage:sv:takeVehicle', function(data)
    local src = source

    if IsOnCooldown(src) then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'cooldownActive', 'error')
        return
    end

    local plate      = data.plate
    local garageName = data.garageName
    local spawnData  = data.spawnCoords

    if not plate or not garageName then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'invalidGarage', 'error')
        return
    end

    local garage = GetGarage(garageName)
    if not garage then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'invalidGarage', 'error')
        return
    end

    if not PlayerCanAccess(src, garage) then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'accessDenied', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Verify ownership and current state
    local row = MySQL.single.await(
        [[SELECT plate, vehicle, state, mods, fuel, sovex_damage
          FROM player_vehicles
          WHERE plate = ? AND citizenid = ? AND garage = ?
          LIMIT 1]],
        { plate, citizenid, garageName }
    )

    if not row then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'vehicleNotOwned', 'error')
        return
    end

    if row.state ~= 0 then
        TriggerClientEvent('sovex_garage:cl:notify', src, 'vehicleOutside', 'error')
        return
    end

    -- Mark vehicle as out (state = 1)
    MySQL.update.await(
        'UPDATE player_vehicles SET state = 1 WHERE plate = ? AND citizenid = ?',
        { plate, citizenid }
    )

    -- Decode stored damage; fall back to defaults if none saved yet
    local damage = row.sovex_damage and json.decode(row.sovex_damage) or {
        engine = Config.DamageDefaults.engine,
        body   = Config.DamageDefaults.body,
        fuel   = Config.DamageDefaults.fuel,
    }

    local mods = row.mods and json.decode(row.mods) or nil

    -- Resolve spawn point (prefer server-authoritative garage spawn over client-sent)
    local spawn = garage.spawn or spawnData
    local spawnCoords = {
        x       = spawn.x or (spawn.coords and spawn.coords.x) or 0.0,
        y       = spawn.y or (spawn.coords and spawn.coords.y) or 0.0,
        z       = spawn.z or (spawn.coords and spawn.coords.z) or 0.0,
        heading = spawn.w or spawn.heading or (spawn.coords and spawn.coords.w) or 0.0,
    }

    DebugPrint(('Sending vehicle %s (%s) to src %d'):format(plate, row.vehicle, src))

    -- FIX: include garageName so client damage tracker knows where to return the vehicle
    TriggerClientEvent('sovex_garage:cl:spawnVehicle', src, {
        model       = row.vehicle,
        plate       = plate,
        mods        = mods,
        damage      = damage,
        garageName  = garageName,
        spawnCoords = spawnCoords,
    })
end)

-- =====================================================
-- EVENT: SAVE DAMAGE
-- Called by client on resource stop or before taking a new vehicle.
-- Persists engine/body/fuel and resets vehicle state to stored (0).
-- =====================================================

RegisterNetEvent('sovex_garage:sv:saveDamage', function(data)
    local src = source

    local plate      = data.plate
    local damage     = data.damage
    local garageName = data.garageName

    if not plate or not damage then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Verify the player owns this vehicle before updating
    local exists = MySQL.scalar.await(
        'SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ? LIMIT 1',
        { plate, citizenid }
    )

    if not exists then
        DebugPrint(('saveDamage: plate %s not owned by %s'):format(plate, citizenid))
        return
    end

    MySQL.update.await(
        [[UPDATE player_vehicles
          SET sovex_damage = ?, state = 0, garage = ?
          WHERE plate = ? AND citizenid = ?]],
        {
            json.encode(damage),
            garageName or 'garage_pillbox',
            plate,
            citizenid,
        }
    )

    DebugPrint(('Damage saved for plate %s (src %d)'):format(plate, src))
end)

-- =====================================================
-- CLEANUP ON PLAYER DROP
-- =====================================================

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
