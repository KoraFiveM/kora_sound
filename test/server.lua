-- Run from the resource directory: lua5.4 test/server.lua
local checks = 0
local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(label, tostring(expected), tostring(actual)))
end

local now = 0
local function start(configure)
    local events, exposed, sent = {}, {}, {}
    function GetGameTimer() return now end
    function RegisterNetEvent(name, callback) events[name] = callback end
    function AddEventHandler(name, callback) events[name] = callback end
    function TriggerClientEvent(name, target, ...) sent[#sent + 1] = { name = name, target = target, args = { ... } } end
    function exports(name, callback) exposed[name] = callback end
    function GetPlayers() return {} end
    Kora = { compat = { provideExport = function() end }, config = dofile('test/config_mock.lua') }
    dofile('config.lua')
    if configure then configure(Config) end
    dofile('server/main.lua')
    local function fire(src, name, ...)
        now = now + 1000 -- clear the per-player cooldown between calls
        source = src
        events[name](...)
        source = nil
    end
    return fire, exposed, sent
end

-- F#406: a client cannot broadcast to every player by default.
local fire, exposed, sent = start()
equal(Config.security.allowClientBroadcast, false, 'client broadcast off by default')
fire(7, 'InteractSound_SV:PlayOnAll', 'security-alarm', 50.0)
equal(#sent, 0, 'client PlayOnAll is dropped')

fire(7, 'InteractSound_SV:PlayOnSource', 'DoorOpen', 0.2)
equal(#sent, 1, 'client PlayOnSource still plays')
equal(sent[1].name, 'InteractSound_CL:PlayOnOne', 'PlayOnSource client event')
equal(sent[1].target, 7, 'PlayOnSource targets the sender')

exposed.PlaySoundAll('Alert', 0.5)
equal(#sent, 2, 'server export still broadcasts')
equal(sent[2].name, 'InteractSound_CL:PlayOnAll', 'export broadcast event')
equal(sent[2].target, -1, 'export broadcast reaches everyone')
equal(sent[2].args[1], 'Alert', 'export broadcast file')

-- Owners who need the legacy third-party behaviour can turn it back on.
fire, exposed, sent = start(function(config) config.security.allowClientBroadcast = true end)
fire(7, 'InteractSound_SV:PlayOnAll', 'Alert', 0.4)
equal(#sent, 1, 'opted-in client PlayOnAll broadcasts')
equal(sent[1].name, 'InteractSound_CL:PlayOnAll', 'opted-in broadcast event')
equal(sent[1].target, -1, 'opted-in broadcast reaches everyone')
fire(7, 'InteractSound_SV:PlayOnAll', 'Alert', 0.4)
equal(#sent, 2, 'opted-in broadcast after cooldown')
print(('%d server checks passed'):format(checks))
