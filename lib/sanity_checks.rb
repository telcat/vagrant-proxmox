begin
	require 'vagrant'
rescue LoadError
	raise 'The Vagrant Proxmox plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.2.0'
	raise 'The Vagrant Proxmox plugin is only compatible with Vagrant 1.2+'
end
