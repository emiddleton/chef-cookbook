tag("chef-server")

include_recipe "couchdb"
include_recipe "java"
include_recipe "nginx"
include_recipe "ssl"
include_recipe "chef"
include_recipe "ruby::rack"

directory "/etc/rabbitmq"
["rabbitmq-env.conf","rabbitmq.config"].each do |f|
  cookbook_file "/etc/rabbitmq/#{f}" do
    owner "root"
    group "root"
    mode "0644"
  end
end

include_recipe "rabbitmq"

portage_package_use "dev-libs/gecode -gist"

{
# 'dev-ruby/rdoc'                  => '3.9.4',            # chef client
#  'dev-ruby/rake'                  => '0.9.2',           # chef client
#  'dev-ruby/bundler'               => '1.0.10',          # chef client
#      'dev-ruby/net-ssh'               => '2.1.4',       # chef client
#        'dev-ruby/net-ssh-gateway'       => '1.1.0',     # chef client
#      'dev-ruby/net-ssh-multi'         => '1.1',         # chef client
#        'dev-ruby/mime-types'            => '1.16-r3',   # chef client
#      'dev-ruby/rest-client'           => '1.6.7',       # chef client
#      'dev-ruby/mixlib-log'            => '1.3.0',       # chef client
#      'dev-ruby/mixlib-config'         => '1.1.2',       # chef client
#      'dev-ruby/mixlib-cli'            => '1.2.2',       # chef client
#      'dev-ruby/mixlib-authentication' => '1.1.4',       # chef client
#        'dev-ruby/yajl-ruby'             => '1.0.0',     # chef client
#        'dev-ruby/systemu'               => '2.4.0',     # chef client
#      'dev-ruby/ohai'                  => '0.6.8',       # chef client
#        'dev-ruby/polyglot'              => '0.3.2',     # chef client
#      'dev-ruby/treetop'               => '1.4.10',      # chef client
#      'dev-ruby/uuidtools'             => '2.1.2',       # chef client
#      'dev-ruby/moneta'                => '0.6.0-r1',    # chef client
#      'dev-ruby/json'                  => '1.4.6',       # chef client
#      'dev-ruby/highline'              => '1.6.2',       # chef client
#        'dev-ruby/abstract'              => '1.0.0-r1',  # chef client
#      'dev-ruby/erubis'                => '2.7.0',       # chef client
#      'dev-ruby/bunny'                 => '0.6.0-r1',    # chef client
#      'dev-ruby/extlib'                => '0.9.15',      # chef client
#    'app-admin/chef'                 => '0.10.4',        # chef client
    'app-admin/chef-solr'            => '0.10.4',        # overlay
      'dev-ruby/fast_xs'               => '0.7.3-r1',    # system
      'dev-ruby/eventmachine'          => '0.12.10-r2',  # system
        'dev-ruby/addressable'           => '2.2.6',     # system
      'dev-ruby/em-http-request'       => '0.2.15',      # overlay
      'dev-ruby/amqp'                  => '0.6.7-r1',    # system
    'app-admin/chef-expander'        => '0.10.4',        # overlay
        'dev-libs/gecode'                => '3.6.0',     # system
      'dev-ruby/dep_selector'          => '0.0.8',       # system
      'dev-ruby/merb-core'             => '1.1.3',       # system
      'dev-ruby/merb-assets'           => '1.1.3',       # system
      'dev-ruby/merb-helpers'          => '1.1.3',       # system
      'dev-ruby/merb-param-protection' => '1.1.3',       # system
#        'dev-ruby/rack'                  => '1.3.4',     # ruby::rack
        'dev-ruby/daemons'               => '1.1.4',     # system
      'www-servers/thin'               => '1.2.11',      # system
    'app-admin/chef-server-api'      => '0.10.4',        # overlay
      'dev-ruby/haml'                  => '3.1.3',       # system
      'dev-ruby/merb-haml'             => '1.1.3',       # system
      'dev-ruby/coderay'               => '1.0.0',       # system
      'dev-ruby/ruby-openid'           => '2.1.8',       # system
    'app-admin/chef-server-webui'    => '0.10.4',        # overlay
  'app-admin/chef-server'          => '0.10.4',          # overlay
}.each do |package_name,package_version|
  portage_package_keywords "=#{package_name}-#{package_version}"
end

# install chef-server
package 'app-admin/chef-server' do
  version '0.10.4'
end

# setup RabbitMQ user/permissions
amqp_pass = get_password("rabbitmq/chef")

execute "rabbitmqctl add_vhost /chef" do
  not_if "rabbitmqctl list_vhosts | grep /chef"
end

execute "rabbitmqctl add_user chef chef" do
  not_if "rabbitmqctl list_users | grep chef"
end

execute "rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'" do
  not_if "rabbitmqctl list_user_permissions chef | grep /chef"
end

execute "rabbitmqctl change_password chef" do
  command "rabbitmqctl change_password chef #{amqp_pass}"
  only_if do
    begin
      b = Bunny.new({
        :spec   => '08',
        :host   => Chef::Config[:amqp_host],
        :port   => Chef::Config[:amqp_port],
        :vhost  => Chef::Config[:amqp_vhost],
        :user   => Chef::Config[:amqp_user],
        :pass   => amqp_pass,
      })
      b.start
      b.stop
      false
    rescue Bunny::ProtocolError
      true
    end
  end
end

file "/etc/chef/amqp_pass" do
  action :delete
end

template "/etc/chef/solr.rb" do
  source "solr.rb.erb"
  owner "chef"
  group "chef"
  mode "0600"
  variables :amqp_pass => amqp_pass
  notifies :reload, "service[chef-solr]", :delayed
  notifies :reload, "service[chef-expander]", :delayed
end

template "/etc/chef/server.rb" do
  source "server.rb.erb"
  owner "chef"
  group "chef"
  mode "0600"
  variables :amqp_pass => amqp_pass
  notifies :reload, "service[chef-server-api]", :delayed
end


directory "/etc/chef/certificates" do
  owner "chef"
  group "root"
  mode "0700"
end

%w(
  backup
  checksums
  sandboxes
).each do |d|
  directory "/var/lib/chef/#{d}" do
    owner "chef"
    group "root"
    mode "0750"
  end
end

# 
# setup Chef solr
#
execute "chef-solr-installer" do
  command  "chef-solr-installer -c /etc/chef/solr.rb -u chef -g root"
  path %w{ /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin }
  not_if { ::File.exists?("/var/lib/chef/solr/home") }
end

cookbook_file "/var/lib/chef/solr/jetty/etc/jetty.xml" do
  source "jetty.xml"
  owner "chef"
  group "root"
  mode "0644"
  notifies :reload, "service[chef-solr]", :delayed
end

cookbook_file "/etc/conf.d/chef-solr" do
  source "chef-solr.confd"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[chef-solr]", :delayed
end

cookbook_file "/etc/init.d/chef-solr" do
  source "chef-solr.initd"
  owner "root"
  group "root"
  mode "0755"
  notifies :reload, "service[chef-solr]", :delayed
end

service "chef-solr" do
  supports :reload => true
  action [:enable, :start]
end
  
# 
# chef expander
#
cookbook_file "/etc/conf.d/chef-expander" do
  source "chef-expander.confd"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[chef-expander]", :delayed
end

cookbook_file "/etc/init.d/chef-expander" do
  source "chef-expander.initd"
  owner "root"
  group "root"
  mode "0755"
  notifies :reload, "service[chef-expander]", :delayed
end

service "chef-expander" do
  supports :reload => true
  action [:enable, :start]
end

#
# Setup chef server api
#
cookbook_file "/etc/conf.d/chef-server-api" do
  source "chef-server-api.confd"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[chef-server-api]", :delayed
end

cookbook_file "/etc/init.d/chef-server-api" do
  source "chef-server-api.initd"
  owner "root"
  group "root"
  mode "0755"
  notifies :reload, "service[chef-server-api]", :delayed
end

service "chef-server-api" do
  supports :reload => true
  action [:enable, :start]
end

# nginx SSL proxy
ssl_ca "/etc/ssl/nginx/#{node[:fqdn]}-ca" do
  notifies :reload, 'service[nginx]', :delayed
end

ssl_certificate "/etc/ssl/nginx/#{node[:fqdn]}" do
  cn node[:fqdn]
  notifies :reload, 'service[nginx]', :delayed
end

%w(
  modules/passenger.conf
  servers/chef-server-webui.conf
).each do |f|
  file "/etc/nginx/#{f}" do
    action :delete
  end
end

nginx_server "chef-server-api" do
  template "chef-server-api.nginx.erb"
end

# CouchDB maintenance
require 'open-uri'

http_request "compact chef couchDB" do
  action :post
  url "#{Chef::Config[:couchdb_url]}/chef/_compact"
  only_if do
    disk_size = 0

    begin
      f = open("#{Chef::Config[:couchdb_url]}/chef")
      disk_size = JSON::parse(f.read)["disk_size"]
      f.close
    rescue ::OpenURI::HTTPError
      nil
    end

    disk_size > 100_000_000
  end
end

%w(
  clients
  cookbooks
  data_bags
  data_bag_items
  id_map
  nodes
  registrations
  roles
  sandboxes
  users
).each do |view|
  http_request "compact chef couchDB view #{view}" do
    action :post
    url "#{Chef::Config[:couchdb_url]}/chef/_compact/#{view}"
    only_if do
      disk_size = 0

      begin
        f = open("#{Chef::Config[:couchdb_url]}/chef/_design/#{view}/_info")
        disk_size = JSON::parse(f.read)["view_index"]["disk_size"]
        f.close
      rescue ::OpenURI::HTTPError
        nil
      end

      disk_size > 100_000_000
    end
  end
end

node.set[:chef][:client][:server_url] = 'http://localhost:4000'

include_recipe 'chef::client'

execute "create-server-client" do
  action :nothing
  command <<-CMD
    knife configure \
      --server-url http://localhost:4000 \
      --key /root/.chef/client.pem \
      --user root \
      --initial --defaults \
      --yes \
      --repository /root/chef /root/chef/site-cookbooks
  CMD
  not_if { ::FileTest.exist?('/root/.chef') }
end

directory "/root/.chef" do
  owner "root"
  group "root"
  mode "0700"
  notifies :run, "execute[create-server-client]", :immediately
end

template "/root/.chef/knife.rb" do
  source "knife.rb"
  owner "root"
  group "root"
  mode "0600"
end
