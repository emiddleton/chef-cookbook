include_recipe 'ruby'

case node[:platform]
when 'gentoo'
  portage_overlay 'chef-gentoo-bootstrap-overlay'

  {
      'dev-ruby/net-ssh'               => '2.1.4',     # system
        'dev-ruby/net-ssh-gateway'       => '1.1.0',   # system
      'dev-ruby/net-ssh-multi'         => '1.1',       # system
        'dev-ruby/mime-types'            => '1.16-r3', # system
      'dev-ruby/rest-client'           => '1.6.7',     # system
      'dev-ruby/mixlib-log'            => '1.3.0',     # overlay
      'dev-ruby/mixlib-config'         => '1.1.2',     # system
      'dev-ruby/mixlib-cli'            => '1.2.2',     # system
      'dev-ruby/mixlib-authentication' => '1.1.4',     # system
        'dev-ruby/yajl-ruby'             => '1.0.0',   # overlay
        'dev-ruby/systemu'               => '2.4.0',   # system
      'dev-ruby/ohai'                  => '0.6.8',     # overlay
      'dev-ruby/treetop'               => '1.4.10',    # system
      'dev-ruby/uuidtools'             => '2.1.2',     # system
      'dev-ruby/moneta'                => '0.6.0-r1',  # system
      'dev-ruby/json'                  => '1.4.6',     # system
      'dev-ruby/highline'              => '1.6.2',     # system
      'dev-ruby/erubis'                => '2.7.0',     # system
      'dev-ruby/bunny'                 => '0.6.0-r1',  # system
      'dev-ruby/extlib'                => '0.9.15',    # system
    'dev-ruby/chef'                  => '0.10.4'       # overlay

  }.each do |package_name,package_version|
    portage_package_keywords "=#{package_name}-#{package_version}"
  end
  portage_package_keywords '=dev-ruby/ruby-shadow-1.4.1-r1'  # system
  package 'dev-ruby/ruby-shadow' do
    version '1.4.1-r1'
  end
end

package 'chef' do
  version '0.10.4'
end

directory "/var/log/chef" do
  group "root"
  mode "0755"
end

directory "/var/lib/chef" do
  owner "chef"
  group "chef"
  mode "0750"
end

directory "/var/lib/chef/cache" do
  group "root"
  mode "0750"
end

cookbook_file "/etc/init.d/chef-client" do
  source "chef-client.initrd"
  owner "root"
  group "root"
  mode "0750"
end

case node[:platform]
when 'gentoo'
  
  template "/etc/conf.d/chef-client" do
    source "chef-client.confd.erb"
    owner "root"
    group "root"
    mode "0644"
  end

when 'centos'

  template "/etc/sysconfig/chef-client" do
    source "chef-client.sysconfig.erb"
    owner "root"
    group "root"
    mode "0640"
  end

end
