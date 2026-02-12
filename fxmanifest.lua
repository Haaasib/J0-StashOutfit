fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'mfhasib'
description 'tebex.haaasib.dev'

client_scripts {
    'client/fw-cl.lua',
    'client/client.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/**/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'locale/*.lua',
    'shared/config.lua',
    'shared/locale.lua'
}

files {
    'stream/*.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

escrow_ignore {
    'shared/*.lua',
    'shared/*.json',
    'client/fw-cl.lua',
    'server/fw-sv.lua',
}