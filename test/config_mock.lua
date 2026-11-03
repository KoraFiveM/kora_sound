-- Minimal Kora.config stand-in: field helpers wrap their default and define
-- returns the plain table of defaults, as the real module does.
local config = {}
local function field(value) return { __field = true, value = value } end
local function unwrap(value)
    if type(value) ~= 'table' then return value end
    if value.__field then return unwrap(value.value) end
    local plain = {}
    for key, child in pairs(value) do plain[key] = unwrap(child) end
    return plain
end
for _, kind in ipairs({ 'boolean', 'string', 'integer', 'number', 'enum', 'object' }) do config[kind] = field end
function config.define(values) return unwrap(values) end
return config
