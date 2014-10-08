begin
	require 'vagrant'
rescue LoadError
	fail 'The Vagrant Proxmox plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.4.0'
	fail 'The Vagrant Proxmox plugin is only compatible with Vagrant 1.2+'
end

if RUBY_VERSION.to_i < 2
	fail 'The Vagrant Proxmox plugin is ony compatible with Ruby 2.0+'
end