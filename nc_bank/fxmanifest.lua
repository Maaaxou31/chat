fx_version 'cerulean'
game 'gta5'

author 'NorthCounty Development'
description 'Système bancaire complet avec ATM, virements et intérêts'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'locales/locales.lua',
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
    'html/img/*.jpg',

    -- Fichiers pour l'app téléphone yseries
    'phone/index.html',
    'phone/style.css',
    'phone/app.js',
    'phone/bank_app.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
