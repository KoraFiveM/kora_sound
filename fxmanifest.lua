fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Sound export + server area sync with falloff, categories, cooldown, loops. Built on qblib.'
version '2.1.0'

dependency 'qblib'

shared_scripts {
    '@qblib/init.lua',
    'config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'client/html/index.html'

files {
    'client/html/index.html',
    'client/html/sounds/*.ogg',
}
