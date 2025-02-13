fx_version 'cerulean'
game 'gta5'

author 'SerpentsByte'
description 'NPC Ped Robbery Script'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

lua54 'yes'