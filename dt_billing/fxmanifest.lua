fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Dhito'
description 'Sistem Billing BY DT SCRIPT ID'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/*.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Tambahkan ini agar MySQL dikenali
    'server/*.lua'
}

dependencies {
    'ox_lib',
    'oxmysql' -- Tambahkan oxmysql sebagai dependency
}
