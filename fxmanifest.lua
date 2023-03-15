fx_version 'adamant'
lua54 'yes'
game 'gta5'

client_scripts {
	'client/*.lua'
} 

server_scripts { 
	'@mysql-async/lib/MySQL.lua',
	'server/*.lua'
} 

ui_page "nui/index.html" 

files {
	'nui/css/materialize.css',
	'nui/css/materialize.min.css',
	'nui/js/materialize.js',
	'nui/js/materialize.min.js',

    'nui/js/app.js', 
	'nui/css/app.css', 
	'nui/index.html'
}

shared_script {
	'config.lua'
}