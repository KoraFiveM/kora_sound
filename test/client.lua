-- Run from the resource directory: lua5.4 test/client.lua
-- Optional arg1 loads an original client for the regression control.
local checks = 0
local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(label, tostring(expected), tostring(actual)))
end

local function start(loggedIn)
    local events, exposed, aliases, messages = {}, {}, {}, {}
    LocalPlayer = { state = { isLoggedIn = loggedIn } }
    function RegisterNetEvent(name, callback) events[name] = callback end
    function SendNUIMessage(message) messages[#messages + 1] = message end
    function exports(name, callback) exposed[name] = callback end
    QB = { compat = { provideExport = function(resource, name, callback)
        equal(resource, 'interact-sound', 'legacy export namespace')
        aliases[name] = callback
    end } }
    dofile('config.lua')
    dofile(arg[1] or 'client/main.lua')
    equal(aliases.PlaySound, exposed.PlaySound, 'legacy play alias')
    equal(aliases.StopSound, exposed.StopSound, 'legacy stop alias')
    return events, exposed, messages
end

local events, exposed, messages = start(true)
equal(table.pack(exposed.PlaySound('DoorOpen')).n, 0, 'play export no-value return')
equal(#messages, 1, 'already loaded player plays immediately after startup')
equal(messages[1].transactionType, 'playSound', 'play transaction')
equal(messages[1].transactionFile, 'DoorOpen', 'sound file argument')
equal(messages[1].transactionVolume, 0.3, 'existing category volume')
equal(messages[1].transactionLoop, false, 'one-shot default')
equal(messages[1].transactionId, nil, 'unnamed one-shot')

for _, state in ipairs({ { value = false }, {} }) do
    events, exposed, messages = start(state.value)
    equal(table.pack(exposed.PlaySound('DoorOpen', 0.7)).n, 0, 'blocked play no-value return')
    events['InteractSound_CL:PlayOnOne']('DoorOpen', 0.7)
    events['InteractSound_CL:PlayOnAll']('DoorOpen', 0.7)
    events['InteractSound_CL:PlayLoop']('DoorOpen', 0.7, 'alarm')
    equal(#messages, 0, 'not-loaded startup blocks all play entry points')

    events['QBCore:Client:OnPlayerLoaded']()
    events['InteractSound_CL:PlayOnOne']('DoorOpen', 0.7)
    events['InteractSound_CL:PlayOnAll']('DoorOpen', 0.7)
    events['InteractSound_CL:PlayLoop']('DoorOpen', 0.7, 'alarm')
    equal(#messages, 3, 'later login enables legacy playback events')
    equal(messages[3].transactionVolume, 0.7, 'explicit volume preserved')
    equal(messages[3].transactionLoop, true, 'loop flag preserved')
    equal(messages[3].transactionId, 'alarm', 'loop id preserved')

    events['QBCore:Client:OnPlayerUnload']()
    equal(table.pack(exposed.PlaySound('DoorOpen')).n, 0, 'unloaded play no-value return')
    events['InteractSound_CL:PlayOnOne']('DoorOpen')
    events['InteractSound_CL:PlayOnAll']('DoorOpen')
    events['InteractSound_CL:PlayLoop']('DoorOpen', nil, 'alarm')
    equal(#messages, 3, 'later logout blocks all playback')
    equal(table.pack(exposed.StopSound('alarm')).n, 0, 'stop export no-value return')
    equal(messages[4].transactionType, 'stopSound', 'stopping remains allowed after logout')
    equal(messages[4].transactionId, 'alarm', 'stop id preserved')
    events['InteractSound_CL:StopSound']('second')
    equal(messages[5].transactionId, 'second', 'legacy stop event preserved')
    equal(table.pack(exposed.StopSound()).n, 0, 'missing stop id no-value return')
    equal(#messages, 5, 'missing stop id sends no message')

    events['QBCore:Client:OnPlayerLoaded']()
    exposed.PlaySound('DoorOpen', 0.2, { loop = true, id = 'again' })
    equal(#messages, 6, 'login after logout enables exported playback')
    equal(messages[6].transactionId, 'again', 'export options preserved')
end
print(('%d client state checks passed'):format(checks))
