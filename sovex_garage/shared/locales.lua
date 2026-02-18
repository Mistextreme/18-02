-- =====================================================
-- LOCALES  –  sovex_garage
-- These strings are forwarded to the NUI via the
-- 'config' message so the UI stays fully translatable.
-- =====================================================

local Locales = {}

-- Active locale key
local LANG = 'en'

-- =====================================================
-- TRANSLATIONS
-- =====================================================
Locales['en'] = {
    -- NUI labels
    vehiclesStored  = 'Your stored vehicles',
    hint            = '↑↓ / wheel: select  •  Enter: take  •  ESC: close',
    stored          = 'STORED',
    out             = 'OUT',
    take            = 'TAKE VEHICLE',
    close           = 'CLOSE',
    fuel            = 'Fuel',
    engine          = 'Engine',
    body            = 'Body',
    tagExcellent    = 'EXCELLENT',
    tagGood         = 'GOOD',
    tagMedium       = 'MEDIUM',
    tagBad          = 'BAD',

    -- Client / server notifications
    garageOpened        = 'Garage opened.',
    noVehicles          = 'You have no stored vehicles here.',
    vehicleTaken        = 'Vehicle retrieved successfully.',
    vehicleOutside      = 'That vehicle is already outside.',
    vehicleNotOwned     = 'You do not own that vehicle.',
    garageClosed        = 'Garage closed.',
    accessDenied        = 'You do not have access to this garage.',
    cooldownActive      = 'Please wait before interacting again.',
    vehicleSpawnFailed  = 'Failed to spawn the vehicle. Try again.',
    invalidGarage       = 'Garage not found.',
}

Locales['es'] = {
    -- NUI labels
    vehiclesStored  = 'Tus vehículos guardados',
    hint            = '↑↓ / rueda: seleccionar  •  Enter: sacar  •  ESC: cerrar',
    stored          = 'GUARDADO',
    out             = 'FUERA',
    take            = 'SACAR VEHÍCULO',
    close           = 'CERRAR',
    fuel            = 'Combustible',
    engine          = 'Motor',
    body            = 'Carrocería',
    tagExcellent    = 'EXCELENTE',
    tagGood         = 'BUENO',
    tagMedium       = 'MEDIO',
    tagBad          = 'MALO',

    -- Client / server notifications
    garageOpened        = 'Garaje abierto.',
    noVehicles          = 'No tienes vehículos guardados aquí.',
    vehicleTaken        = 'Vehículo recuperado correctamente.',
    vehicleOutside      = 'Ese vehículo ya está fuera.',
    vehicleNotOwned     = 'No eres propietario de ese vehículo.',
    garageClosed        = 'Garaje cerrado.',
    accessDenied        = 'No tienes acceso a este garaje.',
    cooldownActive      = 'Espera antes de interactuar de nuevo.',
    vehicleSpawnFailed  = 'Error al generar el vehículo. Inténtalo de nuevo.',
    invalidGarage       = 'Garaje no encontrado.',
}

-- =====================================================
-- PUBLIC HELPER
-- =====================================================

--- Returns the translation string for the given key.
--- Falls back to English if the key is missing in the active locale.
---@param key string
---@return string
function L(key)
    local locale = Locales[LANG] or Locales['en']
    return locale[key] or Locales['en'][key] or key
end

--- Returns the entire locale table for the active language.
--- Used by client/main.lua to send all strings to the NUI at once.
---@return table
function GetLocaleTable()
    local locale = Locales[LANG] or Locales['en']
    -- Merge with English to guarantee every key is present
    local merged = {}
    for k, v in pairs(Locales['en']) do merged[k] = v end
    for k, v in pairs(locale)        do merged[k] = v end
    return merged
end
