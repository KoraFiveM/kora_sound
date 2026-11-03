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

-- F#407/F#408: net entry points are restricted to the sender and validated.
local function point(x) return setmetatable({ x = x }, { __sub = function(a, b) return point(a.x - b.x) end, __len = function(a) return math.abs(a.x) end }) end
local coords = { [1] = 0.0, [2] = 5.0, [3] = 50.0 }
fire, exposed, sent = start()
function GetPlayers() return { '1', '2', '3' } end
function GetPlayerPed(id) return tonumber(id) end
function GetEntityCoords(ped) return point(coords[ped]) end
fire(1, 'InteractSound_SV:PlayOnOne', 2, 'Alert', 1.0)
equal(#sent, 0, 'PlayOnOne to another player is dropped')
fire(1, 'InteractSound_SV:PlayOnOne', 1, 'Alert', 0.5)
equal(#sent, 1, 'PlayOnOne to self still plays')
equal(sent[1].target, 1, 'PlayOnOne self target')

fire(1, 'InteractSound_SV:PlayOnSource', 'Alert', 50.0)
equal(sent[2].args[2], 1.0, 'volume above 1 is clamped')
fire(1, 'InteractSound_SV:PlayOnSource', 'Alert', -3)
equal(sent[3].args[2], 0.0, 'negative volume is clamped')
fire(1, 'InteractSound_SV:PlayOnSource', 'Alert', '0.4')
equal(sent[4].args[2], 0.4, 'numeric string volume is coerced')
fire(1, 'InteractSound_SV:PlayOnSource', 'Alert', { 1 })
equal(sent[5].args[2], 0.6, 'non-number volume falls back to the category default')
fire(1, 'InteractSound_SV:PlayOnSource', 'Alert', 0 / 0)
equal(sent[6].args[2], 0.6, 'NaN volume falls back to the default')

local count = #sent
for _, bad in ipairs({ '../../x', 'a/b', 'a.b', '', string.rep('a', 65), 12, true, {} }) do
    fire(1, 'InteractSound_SV:PlayOnSource', bad, 0.2)
end
fire(1, 'InteractSound_SV:PlayOnSource', nil, 0.25)
equal(#sent, count, 'invalid sound file names are dropped')
fire(1, 'InteractSound_SV:PlayOnSource', 'security-alarm', 0.2)
equal(#sent, count + 1, 'valid file names with dashes play')

-- PlayWithinDistance: radius capped for clients, junk radius does not throw.
count = #sent
fire(1, 'InteractSound_SV:PlayWithinDistance', 300.0, 'DoorOpen', 0.25)
equal(#sent, count + 2, 'client radius capped to 10 m (players at 0 and 5 only)')
count = #sent
fire(1, 'InteractSound_SV:PlayWithinDistance', 'huge', 'DoorOpen', 0.25)
equal(#sent, count + 2, 'non-number radius falls back to the default range')
fire(1, 'InteractSound_SV:PlayWithinDistance', 5.0, '../x', 0.25)
equal(#sent, count + 2, 'invalid file in PlayWithinDistance is dropped')

-- Server exports keep their larger radius but volumes are still clamped.
count = #sent
exposed.PlaySoundInArea(point(0.0), 100.0, 'DoorOpen', 9)
equal(#sent, count + 3, 'server export radius is not capped to the client limit')
equal(sent[count + 1].args[2], 1.0, 'export volume clamped')
print(('%d server checks passed'):format(checks))
