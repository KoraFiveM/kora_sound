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
    radius = math.min(radius or Config.defaultRange, AREA_DISTANCE_LIMIT)
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
 QB.compat.provideExport('interact-sound', 'PlaySound', playOnSource)
 QB.compat.provideExport('interact-sound', 'PlaySoundAll', playOnAll)
 QB.compat.provideExport('interact-sound', 'PlaySoundInArea', playInArea)
 QB.compat.provideExport('interact-sound', 'StopSound', stopSound)

RegisterNetEvent('InteractSound_SV:PlayOnOne', function(clientNetId, soundFile, soundVolume)
    if not passesCooldown(source) then return end
    playOnSource(clientNetId, soundFile, soundVolume)
end)

RegisterNetEvent('InteractSound_SV:PlayOnSource', function(soundFile, soundVolume)
    if not passesCooldown(source) then return end
    playOnSource(source, soundFile, soundVolume)
end)

RegisterNetEvent('InteractSound_SV:PlayOnAll', function(soundFile, soundVolume)
    if not passesCooldown(source) then return end
    playOnAll(soundFile, soundVolume)
end)

RegisterNetEvent('InteractSound_SV:PlayWithinDistance', function(maxDistance, soundFile, soundVolume)
    if not passesCooldown(source) then return end
    playInArea(GetEntityCoords(GetPlayerPed(source)), maxDistance, soundFile, soundVolume)
end)

AddEventHandler('playerDropped', function()
    playerCooldowns[source] = nil
end)
