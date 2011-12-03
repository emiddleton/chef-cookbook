include_recipe 'chef'
  
template "/etc/chef/client.rb" do
  source "client.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[chef-client]", :delayed
end

service "chef-client" do
  supports :reload => true
  action [:enable, :start]
end

cookbook_file "/etc/logrotate.d/chef" do
  source "chef.logrotate"
  owner "root"
  group "root"
  mode "0644"
end

file "/var/log/chef/client.log" do
  owner "root"
  group "root"
  mode "0600"
end
