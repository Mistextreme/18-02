fx_version 'cerulean'
game 'gta5'

author 'Sovex'
description 'sovex_garage - Garage system for QBCore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locales.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

escrow_ignore {
    'shared/config.lua',
    'shared/locales.lua'
}

lua54 'yes'

dependency '/assetpacks'
