require 'pathname'
require 'log4r'
require 'active_support/core_ext/object/try'

require 'sanity_checks'
require 'vagrant-proxmox/plugin'
require 'vagrant-proxmox/errors'
require 'vagrant-proxmox/proxmox/connection'


module VagrantPlugins
	module Proxmox
		lib_path = Pathname.new(File.expand_path '../vagrant-proxmox', __FILE__)
		autoload :Action, lib_path.join('action')
		autoload :Errors, lib_path.join('errors')

		def self.source_root
			@source_root ||= Pathname.new(File.expand_path '../../', __FILE__)
		end
	end
end
