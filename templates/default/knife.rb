# Configuration File For Chef (knife)

node_name          "root"
client_key         "/root/.chef/client.pem"

log_level          :info
log_location       STDOUT

ssl_verify_mode    :verify_none
chef_server_url    "<%= node[:chef][:client][:server_url] %>"

cookbook_path      ["/root/chef/cookbooks", "/root/chef/site-cookbooks"]
