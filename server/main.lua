local AREA_DISTANCE_LIMIT = 300.0

local playerCooldowns = {}
local activeLoops = {}

local function passesCooldown(src)
    local now = GetGameTimer()
    local last = playerCooldowns[src]
    if last and (now - last) < Config.cooldownMs then
        return false
    end
    playerCooldowns[src] = now
    return true
end

local function playOnSource(src, soundFile, volume, options)
    options = options or {}
    local finalVolume = Config.resolveVolume(soundFile, volume)

    if options.loop and options.id then
        activeLoops[options.id] = activeLoops[options.id] or { recipients = {} }
        activeLoops[options.id].recipients[src] = true
        TriggerClientEvent('InteractSound_CL:PlayLoop', src, soundFile, finalVolume, options.id)
    else
        TriggerClientEvent('InteractSound_CL:PlayOnOne', src, soundFile, finalVolume)
    end
end

local function playOnAll(soundFile, volume, options)
    options = options or {}
    local finalVolume = Config.resolveVolume(soundFile, volume)

    if options.loop and options.id then
        activeLoops[options.id] = { all = true }
        TriggerClientEvent('InteractSound_CL:PlayLoop', -1, soundFile, finalVolume, options.id)
    else
        TriggerClientEvent('InteractSound_CL:PlayOnAll', -1, soundFile, finalVolume)
    end
end

local function playInArea(coords, radius, soundFile, volume, options)
    options = options or {}
    radius = tonumber(radius)
    if not radius or radius ~= radius then radius = Config.defaultRange end
    radius = math.min(radius, AREA_DISTANCE_LIMIT)
    local baseVolume = Config.resolveVolume(soundFile, volume)

    if options.loop and options.id then
        activeLoops[options.id] = { recipients = {} }
    end

    for _, playerId in ipairs(GetPlayers()) do
        local pId = tonumber(playerId)
        local distance = #(GetEntityCoords(GetPlayerPed(playerId)) - coords)

        if distance <= radius then
            local finalVolume = Config.falloffVolume(baseVolume, distance, radius)

            if options.loop and options.id then
                activeLoops[options.id].recipients[pId] = true
                TriggerClientEvent('InteractSound_CL:PlayLoop', pId, soundFile, finalVolume, options.id)
            else
                TriggerClientEvent('InteractSound_CL:PlayOnOne', pId, soundFile, finalVolume)
            end
        end
    end
end

local function stopSound(id, target)
    if not id then return end

    if target then
        TriggerClientEvent('InteractSound_CL:StopSound', target, id)
    else
        local loop = activeLoops[id]
        if not loop or loop.all then
            TriggerClientEvent('InteractSound_CL:StopSound', -1, id)
        else
            for pId in pairs(loop.recipients) do
                TriggerClientEvent('InteractSound_CL:StopSound', pId, id)
            end
        end
    end

    activeLoops[id] = nil
end

exports('PlaySound', playOnSource)         -- (src, file, volume?, options?)
exports('PlaySoundAll', playOnAll)         -- (file, volume?, options?)
exports('PlaySoundInArea', playInArea)     -- (coords, radius, file, volume?, options?)
exports('StopSound', stopSound)            -- (id, target?)
Kora.compat.provideExport('interact-sound', 'PlaySound', playOnSource)
Kora.compat.provideExport('interact-sound', 'PlaySoundAll', playOnAll)
Kora.compat.provideExport('interact-sound', 'PlaySoundInArea', playInArea)
Kora.compat.provideExport('interact-sound', 'StopSound', stopSound)

-- Client-sent entry points: sounds stay on the sender (or near them), file names
-- are checked and volumes are clamped in Config.resolveVolume.
RegisterNetEvent('InteractSound_SV:PlayOnOne', function(clientNetId, soundFile, soundVolume)
    local src = source
    if tonumber(clientNetId) ~= src then return end -- cannot target other players
    if not Config.isSoundFile(soundFile) then return end
    if not passesCooldown(src) then return end
    playOnSource(src, soundFile, soundVolume)
end)

RegisterNetEvent('InteractSound_SV:PlayOnSource', function(soundFile, soundVolume)
    local src = source
    if not Config.isSoundFile(soundFile) then return end
    if not passesCooldown(src) then return end
    playOnSource(src, soundFile, soundVolume)
end)

-- Off by default: any client could play any sound to the whole server.
-- Server scripts use the PlaySoundAll export instead.
RegisterNetEvent('InteractSound_SV:PlayOnAll', function(soundFile, soundVolume)
    if not Config.security.allowClientBroadcast then return end
    if not Config.isSoundFile(soundFile) then return end
    if not passesCooldown(source) then return end
    playOnAll(soundFile, soundVolume)
end)

RegisterNetEvent('InteractSound_SV:PlayWithinDistance', function(maxDistance, soundFile, soundVolume)
    local src = source
    if not Config.isSoundFile(soundFile) then return end
    if not passesCooldown(src) then return end
    maxDistance = tonumber(maxDistance)
    if not maxDistance or maxDistance ~= maxDistance then maxDistance = Config.defaultRange end
    playInArea(GetEntityCoords(GetPlayerPed(src)), math.min(maxDistance, Config.netMaxDistance), soundFile, soundVolume)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerCooldowns[src] = nil
    for id, loop in pairs(activeLoops) do
        if loop.recipients then
            loop.recipients[src] = nil
            if next(loop.recipients) == nil then activeLoops[id] = nil end
        end
    end
end)
