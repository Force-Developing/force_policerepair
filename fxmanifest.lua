fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'force_policerepair'
author 'Force Developments <discord:@force3883>'
description 'Repair bay for police and other jobs: drive in, press E and a mechanic repairs your vehicle. ESX, QBCore and QBox.'
version '2.0.0'

dependencies {
    '/onesync',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/functions.lua',
}

server_scripts {
    'server/custom/frameworks/*.lua',
    'server/main.lua',
}

client_scripts {
    'client/custom/frameworks/*.lua',
    'client/main.lua',
}

files {
    'locales/*.json',
}
