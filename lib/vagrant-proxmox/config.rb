module VagrantPlugins
	module Proxmox
		class Config < Vagrant.plugin('2', :config)

			# The Proxmox REST API endpoint
			#
			# @return [String]
			attr_accessor :endpoint

			# The Proxmox user name
			#
			# @return [String]
			attr_accessor :user_name

			# The Proxmox password
			#
			# @return [String]
			attr_accessor :password

			# The openvz os template to use for the virtual machines
			#
			# @return [String]
			attr_accessor :os_template

			# The openvz os template file to upload and use for the virtual machines
			#
			# @return [String]
			attr_accessor :template_file

			# The id range to use for the virtual machines
			#
			# @return [Range]
			attr_accessor :vm_id_range

			# The prefix for the virtual machine name
			#
			# @return [String]
			attr_accessor :vm_name_prefix

			# Amount of RAM for the virtual machine in MB
			#
			# @return [Integer]
			attr_accessor :vm_memory

			# The maximum timeout for a proxmox server task (in seconds)
			#
			# @return [Integer]
			attr_accessor :task_timeout

			# The interval between two proxmox task status retrievals (in seconds)
			#
			# @return [Integer, Proc]
			attr_accessor :task_status_check_interval

			# The maximum timeout for a ssh connection to a virtual machine (in seconds)
			#
			# @return [Integer]
			attr_accessor :ssh_timeout

			# The interval between two ssh reachability status retrievals (in seconds)
			#
			# @return [Integer, Proc]
			attr_accessor :ssh_status_check_interval

			def initialize
				@endpoint = UNSET_VALUE
				@user_name = UNSET_VALUE
				@password = UNSET_VALUE
				@os_template = UNSET_VALUE
				@template_file = UNSET_VALUE
				@vm_id_range = 900..999
				@vm_name_prefix = 'vagrant_'
				@vm_memory = 512
				@task_timeout = 60
				@task_status_check_interval = 2
				@ssh_timeout = 60
				@ssh_status_check_interval = 5
			end

			# This is the hook that is called to finalize the object before it is put into use.
			def finalize!
				@endpoint = nil if @endpoint == UNSET_VALUE
				@user_name = nil if @user_name == UNSET_VALUE
				@password = nil if @password == UNSET_VALUE
				@template_file = nil if @template_file == UNSET_VALUE
				@os_template = "local:vztmpl/#{File.basename @template_file}" if @template_file
				@os_template = nil if @os_template == UNSET_VALUE
			end

			def validate machine
				errors = []
				errors << I18n.t('vagrant_proxmox.errors.no_endpoint_specified') unless @endpoint
				errors << I18n.t('vagrant_proxmox.errors.no_user_name_specified') unless @user_name
				errors << I18n.t('vagrant_proxmox.errors.no_password_specified') unless @password
				errors << I18n.t('vagrant_proxmox.errors.no_os_template_or_template_file_specified') unless @os_template || @template_file
				{'Proxmox Provider' => errors}
			end

		end
	end
end
