fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Sound export + server area sync with falloff, categories, cooldown, loops. Built on kora_lib.'
version '0.2.1'

dependency 'kora_lib'

shared_scripts {
    '@kora_lib/init.lua',
    'config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'client/html/index.html'

files {
    'client/html/index.html',
    'client/html/sounds/*.ogg',
}
