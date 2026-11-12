local hasPlayerLoaded = LocalPlayer.state.isLoggedIn == true

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() hasPlayerLoaded = true end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() hasPlayerLoaded = false end)

-- options = { loop = boolean, id = string }  -- id is required to loop or to stop it later
local function playSound(soundFile, volume, options)
    if not hasPlayerLoaded then return end
    options = options or {}

    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = soundFile,
        transactionVolume = Config.resolveVolume(soundFile, volume),
        transactionLoop = options.loop or false,
        transactionId = options.id,
    })
end

local function stopSound(id)
    if not id then return end
    SendNUIMessage({ transactionType = 'stopSound', transactionId = id })
end

exports('PlaySound', playSound)
exports('StopSound', stopSound)

RegisterNetEvent('InteractSound_CL:PlayOnOne', function(soundFile, volume) playSound(soundFile, volume) end)
RegisterNetEvent('InteractSound_CL:PlayOnAll', function(soundFile, volume) playSound(soundFile, volume) end)

RegisterNetEvent('InteractSound_CL:PlayLoop', function(soundFile, volume, id)
    playSound(soundFile, volume, { loop = true, id = id })
end)
RegisterNetEvent('InteractSound_CL:StopSound', function(id) stopSound(id) end)
Kora.compat.provideExport('interact-sound', 'PlaySound', playSound)
Kora.compat.provideExport('interact-sound', 'StopSound', stopSound)