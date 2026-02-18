fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'C2 Studios'
description 'Universal Vending Machine (ESX + QBCore)'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

-- Only hard requirements
dependencies {
    'ox_target'
}


ui_page 'html/index.html'

files {
    'html/*.*',
    'html/**/*.*'
}

escrow_ignore {
    'config.lua'
}

dependency '/assetpacks'