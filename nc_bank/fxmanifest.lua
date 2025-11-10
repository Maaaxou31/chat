fx_version 'cerulean'
game 'gta5'

author 'NorthCounty Development'
description 'Système bancaire complet avec ATM, virements et intérêts'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'locales/fr.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/atm.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.jpg'
}

dependencies {
    'es_extended',
    'oxmysql'
}
