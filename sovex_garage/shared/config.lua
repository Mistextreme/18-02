Config = {}

-- =====================================================
-- FRAMEWORK
-- =====================================================
Config.Framework = 'qbcore' -- 'qbcore' only (extendable)

-- =====================================================
-- DEBUG
-- =====================================================
Config.Debug = false

-- =====================================================
-- GENERAL SETTINGS
-- =====================================================
Config.Cooldown          = 3000   -- ms between garage interactions
Config.SpawnDistance     = 5.0    -- metres from spawn point where the vehicle appears
Config.NotifyStyle       = 'ox'   -- 'ox' | 'qb'  (which notify system to use)

-- When true the resource reads garages from the DB at start.
-- When false it only uses Config.Garages below.
Config.UseDatabase       = true

-- =====================================================
-- UI / THEME  (sent to NUI via 'config' message)
-- =====================================================
Config.Theme = {
    primary = '#3aa0ff',
    bg      = 'rgba(10,10,12,0.78)',
    border  = 'rgba(255,255,255,0.10)',
    text    = '#ffffff',
    muted   = 'rgba(255,255,255,0.55)',
    good    = '#35d07f',
    warn    = '#f1c40f',
    bad     = '#e74c3c',
}

-- =====================================================
-- OX_TARGET OPTIONS
-- =====================================================
Config.TargetDistance = 2.5   -- sphere radius for ox_target
Config.TargetIcon     = 'fas fa-warehouse'
Config.TargetLabel    = 'Open Garage'

-- =====================================================
-- VEHICLE SPAWN OFFSET
-- Offsets from the garage spawn point (heading-relative)
-- applied when spawning multiple vehicles so they don't overlap.
-- =====================================================
Config.SpawnOffsets = {
    { x =  0.0, y = 0.0, z = 0.0 },
    { x =  6.0, y = 0.0, z = 0.0 },
    { x = -6.0, y = 0.0, z = 0.0 },
}

-- =====================================================
-- FALLBACK GARAGES (used when Config.UseDatabase = false
-- OR to seed the DB on first run via server/main.lua)
-- =====================================================
Config.Garages = {
    {
        name        = 'garage_pillbox',
        type        = 'public',
        label       = 'Pillbox Garage',
        access_type = 'public',   -- 'public' | 'job' | 'gang' | 'private'
        access_data = nil,        -- e.g. 'police' for job-restricted garages
        coords      = vector3(213.9, -809.5, 30.7),
        spawn       = {
            coords  = vector3(211.9, -800.9, 30.7),
            heading = 340.0,
        },
    },
    {
        name        = 'garage_ls_customs',
        type        = 'public',
        label       = 'LS Customs Garage',
        access_type = 'public',
        access_data = nil,
        coords      = vector3(-357.4, -135.0, 38.7),
        spawn       = {
            coords  = vector3(-336.0, -136.9, 38.8),
            heading = 200.0,
        },
    },
    {
        name        = 'garage_airport',
        type        = 'public',
        label       = 'Airport Garage',
        access_type = 'job',
        access_data = 'pilot',
        coords      = vector3(-1037.3, -2738.4, 20.2),
        spawn       = {
            coords  = vector3(-1058.2, -2727.3, 20.2),
            heading = 140.0,
        },
    },
}

-- =====================================================
-- DAMAGE THRESHOLDS
-- Values are 0‑1000 (GTA native bodyHealth / engineHealth)
-- Percentage displayed in NUI is computed as (value/1000)*100
-- =====================================================
Config.DamageDefaults = {
    fuel   = 100.0,
    engine = 1000.0,
    body   = 1000.0,
}
