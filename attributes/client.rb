default[:chef][:client][:interval] = '1800'
default[:chef][:client][:splay] = '20'
default[:chef][:client][:log_level] = 'info'
default[:chef][:client][:server_url] = "https://chef.#{node[:domain]}"
