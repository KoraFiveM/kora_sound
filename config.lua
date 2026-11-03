Config = Kora.config.define({
    security = Kora.config.object({
        allowClientBroadcast = Kora.config.boolean(false, {
            label = 'Let players play sounds to everyone',
            description = 'Accept the legacy InteractSound_SV:PlayOnAll event from clients. Any player can then play any sound to the whole server. Server scripts can always use exports.kora_sound:PlaySoundAll.',
            scope = 'server',
        }),
    }),
})

Config.defaultVolume = 0.3
Config.defaultRange = 30.0     -- used when playInArea is called without a radius
Config.minFalloffVolume = 0.05 -- floor volume at the edge of range, not a hard cutoff
Config.cooldownMs = 150        -- per-player anti-spam on the legacy net-event entry points

-- Category presets used when a caller doesn't pass an explicit volume.
Config.categories = {
    ui = 0.25,
    interaction = 0.3,
    alarm = 0.6,
    ambient = 0.4,
}

-- Maps a sound file name to one of the categories above. Anything not
-- listed falls back to Config.defaultVolume.
Config.soundCategory = {
    Cuff = 'interaction', Uncuff = 'interaction', handcuff = 'interaction', ziptie = 'interaction',
    DoorOpen = 'interaction', DoorClose = 'interaction', lockpick = 'interaction',
    unlock = 'interaction', lock = 'interaction', keys = 'interaction', keydoors = 'interaction',

    Alert = 'alarm', ['security-alarm'] = 'alarm', warehousealert = 'alarm', warehousealert2 = 'alarm',
    panic = 'alarm', beltalarm = 'alarm', RumbleStart = 'alarm',

    radiostatic1 = 'ambient', radiostatic2 = 'ambient', radiostatic3 = 'ambient',
    ventilator = 'ambient', coffee_machine = 'ambient', vending_machine = 'ambient',
}

-- Explicit volume wins, then the sound's category preset, then the global default.
function Config.resolveVolume(soundFile, explicitVolume)
    if explicitVolume then return explicitVolume end

    local category = Config.soundCategory[soundFile]
    if category and Config.categories[category] then
        return Config.categories[category]
    end

    return Config.defaultVolume
end

-- Linear falloff from `volume` at distance 0 down to Config.minFalloffVolume
-- at `radius`, floored rather than cutting off hard.
function Config.falloffVolume(volume, distance, radius)
    if not radius or radius <= 0 then return volume end
    local factor = 1 - math.min(distance / radius, 1)
    return math.max(volume * factor, Config.minFalloffVolume)
end
