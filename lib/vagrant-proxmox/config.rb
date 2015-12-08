module VagrantPlugins
	module Proxmox
		class Config < Vagrant.plugin('2', :config)

			# The Proxmox REST API endpoint
			#
			# @return [String]
			attr_accessor :endpoint

			# The Proxmox preferred cluster node
			#
			# @return [String]
			attr_accessor :selected_node

			# The Proxmox user name
			#
			# @return [String]
			attr_accessor :user_name

			# The Proxmox password
			#
			# @return [String]
			attr_accessor :password

			# The virtual machine type, e.g. :openvz or :qemu or :lxc
			#
			# @return [Symbol]
			attr_accessor :vm_type

			# The openvz os template to use for the virtual machine
			#
			# @return [String]
			attr_accessor :openvz_os_template

			# The openvz os template file to upload and use for the virtual machine
			#
			# @return [String]
			attr_accessor :openvz_template_file

			# Should the openvz os template be replaced (deleted before upload)?
			#
			# @return [Boolean]
			attr_accessor :replace_openvz_template_file

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

			# The vm disk size to use for the virtual machine, e.g. '30G'
			#
			# @return [String]
			attr_accessor :vm_disk_size

			# The vm storage to use for the virtual machine, e.g. 'local', 'raid', 'cephstore'
			# defaults to 'raid' for backwards compatability
			#
			# @return [String]
			attr_accessor :vm_storage

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

			# The maximum timeout for a proxmox server task if it's an upload (in seconds)
			#
			# @return [Integer]
			attr_accessor :imgcopy_timeout

			# The qemu virtual machine operating system, e.g. :l26
			#
			# @return [Symbol]
			attr_accessor :qemu_os

			# The number of cores per socket
			#
			# @return [Integer]
			attr_accessor :qemu_cores

			# The number of CPU sockets
			#
			# @return [Integer]
			attr_accessor :qemu_sockets

			# The qemu iso file to use for the virtual machine
			#
			# @return [String]
			attr_accessor :qemu_iso

			# The qemu iso file to upload and use for the virtual machine
			#
			# @return [String]
			attr_accessor :qemu_iso_file

			# Should the qemu iso file replaced (deleted before upload)?
			#
			# @return [Boolean]
			attr_accessor :replace_qemu_iso_file

			# The qemu disk size to use for the virtual machine, e.g. '30G'
			#
			# @return [String]
			attr_accessor :qemu_disk_size

			# The qemu storage to use for the virtual machine, e.g. 'local', 'raid', 'cephstore'
			# defaults to 'raid' for backwards compatability
			#
			# @return [String]
			attr_accessor :qemu_storage

			# The qemu network interface card model, e.g. 'e1000', 'virtio'
			# defaults to 'e1000' for backwards compatability
			#
			# @return [String]
			attr_accessor :qemu_nic_model

			# The qemu network bridge, e.g. 'vmbr0'
			# defaults to 'vmbr0' for backwards compatability
			#
			# @return [String]
			attr_accessor :qemu_bridge

			def initialize
				@endpoint = UNSET_VALUE
				@selected_node = UNSET_VALUE
				@user_name = UNSET_VALUE
				@password = UNSET_VALUE
				@vm_type = UNSET_VALUE
				@openvz_os_template = UNSET_VALUE
				@openvz_template_file = UNSET_VALUE
				@replace_openvz_template_file = false
				@vm_id_range = 900..999
				@vm_name_prefix = 'vagrant_'
				@vm_memory = 512
				@vm_disk_size = '20G'
				@vm_storage = 'local'
				@task_timeout = 60
				@task_status_check_interval = 2
				@ssh_timeout = 60
				@ssh_status_check_interval = 5
				@imgcopy_timeout = 120
				@qemu_os = UNSET_VALUE
				@qemu_cores = 1
				@qemu_sockets = 1
				@qemu_iso = UNSET_VALUE
				@qemu_iso_file = UNSET_VALUE
				@replace_qemu_iso_file = false
				@qemu_disk_size = UNSET_VALUE
				@qemu_storage = 'raid'
				@qemu_nic_model = 'e1000'
				@qemu_bridge = 'vmbr0'
			end

			# This is the hook that is called to finalize the object before it is put into use.
			def finalize!
				@endpoint = nil if @endpoint == UNSET_VALUE
				@selected_node = nil if @endpoint == UNSET_VALUE
				@user_name = nil if @user_name == UNSET_VALUE
				@password = nil if @password == UNSET_VALUE
				@vm_type = nil if @vm_type == UNSET_VALUE
				@openvz_template_file = nil if @openvz_template_file == UNSET_VALUE
				@openvz_os_template = "local:vztmpl/#{File.basename @openvz_template_file}" if @openvz_template_file
				@openvz_os_template = nil if @openvz_os_template == UNSET_VALUE
				@qemu_os = nil if @qemu_os == UNSET_VALUE
				@qemu_iso_file = nil if @qemu_iso_file == UNSET_VALUE
				@qemu_iso = "local:iso/#{File.basename @qemu_iso_file}" if @qemu_iso_file
				@qemu_iso = nil if @qemu_iso == UNSET_VALUE
				@qemu_disk_size = nil if @qemu_disk_size == UNSET_VALUE
				@qemu_disk_size = convert_disk_size_to_gigabyte @qemu_disk_size if @qemu_disk_size
                @vm_disk_size = convert_disk_size_to_gigabyte @vm_disk_size if @vm_disk_size
			end

			def validate machine
				errors = []
				errors << I18n.t('vagrant_proxmox.errors.no_endpoint_specified') unless @endpoint
				errors << I18n.t('vagrant_proxmox.errors.no_user_name_specified') unless @user_name
				errors << I18n.t('vagrant_proxmox.errors.no_password_specified') unless @password
				errors << I18n.t('vagrant_proxmox.errors.no_vm_type_specified') unless @vm_type
				if @vm_type == :openvz
					errors << I18n.t('vagrant_proxmox.errors.no_openvz_os_template_or_openvz_template_file_specified_for_type_openvz') unless @openvz_os_template || @openvz_template_file
				end
				if @vm_type == :qemu
					errors << I18n.t('vagrant_proxmox.errors.no_qemu_os_specified_for_vm_type_qemu') unless @qemu_os
					errors << I18n.t('vagrant_proxmox.errors.no_qemu_iso_or_qemu_iso_file_specified_for_vm_type_qemu') unless @qemu_iso || @qemu_iso_file
					errors << I18n.t('vagrant_proxmox.errors.no_qemu_disk_size_specified_for_vm_type_qemu') unless @qemu_disk_size
				end
				{'Proxmox Provider' => errors}
			end

			private
			def convert_disk_size_to_gigabyte disk_size
				case disk_size[-1]
					when 'G'
						disk_size[0..-2]
					else
						disk_size
				end
			end
		end
	end
end
