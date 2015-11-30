require 'vagrant/action/builder'
require 'pathname'

module VagrantPlugins
	module Proxmox
		module Action

			include Vagrant::Action::Builtin

			def self.action_read_state
				Vagrant::Action::Builder.new.tap do |b|
					b.use ConfigValidate
					b.use ConnectProxmox
					b.use ReadState
				end
			end

			def self.action_up
				Vagrant::Action::Builder.new.tap do |b|
					b.use ConfigValidate
					b.use ConnectProxmox
					b.use Call, IsCreated do |env1, b1|
						if env1[:result]
							b1.use Call, IsStopped do |env2, b2|
								if env2[:result]
									b2.use Provision
									b2.use StartVm
									b2.use SyncFolders
								else
									b2.use MessageAlreadyRunning
								end
							end
						else
							b1.use GetNodeList
							b1.use SelectNode
							b1.use Provision
							if env1[:machine].provider_config.vm_type == :openvz
								b1.use Call, UploadTemplateFile do |env2, b2|
									if env2[:result] == :ok
										b2.use CreateVm
										b2.use StartVm
										b2.use SyncFolders
									elsif env2[:result] == :file_not_found
										b2.use MessageFileNotFound
									elsif env2[:result] == :server_upload_error
										b2.use MessageUploadServerError
									end
								end
							elsif env1[:machine].provider_config.vm_type == :lxc
								b1.use Call, UploadTemplateFile do |env2, b2|
									if env2[:result] == :ok
										b2.use CreateVm
										b2.use StartVm
										b2.use SyncFolders
									elsif env2[:result] == :file_not_found
										b2.use MessageFileNotFound
									elsif env2[:result] == :server_upload_error
										b2.use MessageUploadServerError
									end
								end
							elsif env1[:machine].provider_config.vm_type == :qemu
								b1.use Call, UploadIsoFile do |env2, b2|
									if env2[:result] == :ok
										b2.use CreateVm
										b2.use StartVm
										b2.use SyncFolders
									elsif env2[:result] == :file_not_found
										b2.use MessageFileNotFound
									elsif env2[:result] == :server_upload_error
										b2.use MessageUploadServerError
									end
								end
							end
						end
					end
				end
			end

		def self.action_provision
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use Call, IsCreated do |env1, b1|
					if env1[:result]
						b1.use Call, IsStopped do |env2, b2|
							if env2[:result]
								b2.use MessageNotRunning
							else
								b2.use Provision
								b2.use SyncFolders
							end
						end
					else
						b1.use MessageNotCreated
					end
				end
			end
		end

		def self.action_halt
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use Call, IsCreated do |env1, b1|
					if env1[:result]
						b1.use Call, IsStopped do |env2, b2|
							if env2[:result]
								b2.use MessageAlreadyStopped
							else
								b2.use ConnectProxmox
								b2.use ShutdownVm
							end
						end
					else
						b1.use MessageNotCreated
					end
				end
			end
		end

		# This action is called to destroy the remote machine.
		def self.action_destroy
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use ConnectProxmox
				b.use Call, IsCreated do |env1, b1|
					if env1[:result]
						b1.use Call, ::Vagrant::Action::Builtin::DestroyConfirm do |env2, b2|
							if env2[:result]
								b2.use Call, IsStopped do |env3, b3|
									b3.use ShutdownVm unless env3[:result]
									b3.use DestroyVm
									b3.use ::Vagrant::Action::Builtin::ProvisionerCleanup
									b3.use CleanupAfterDestroy
								end
							else
								b2.use ::VagrantPlugins::ProviderVirtualBox::Action::MessageWillNotDestroy
							end
						end
					else
						b1.use MessageNotCreated
					end
				end
			end
		end

		def self.action_read_ssh_info
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use ConnectProxmox
				b.use ReadSSHInfo
			end
		end

		def self.action_ssh
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use Call, IsCreated do |env1, b1|
					if env1[:result]
						b1.use Call, IsStopped do |env2, b2|
							if env2[:result]
								b2.use MessageNotRunning
							else
								b2.use SSHExec
							end
						end
					else
						b1.use MessageNotCreated
					end
				end
			end
		end

		def self.action_ssh_run
			Vagrant::Action::Builder.new.tap do |b|
				b.use ConfigValidate
				b.use Call, IsCreated do |env1, b1|
					if env1[:result]
						b1.use Call, IsStopped do |env2, b2|
							if env2[:result]
								b2.use MessageNotRunning
							else
								b2.use SSHRun
							end
						end
					else
						b1.use MessageNotCreated
					end
				end
			end
		end

		action_root = Pathname.new(File.expand_path '../action', __FILE__)
		autoload :ProxmoxAction, action_root.join('proxmox_action')
		autoload :ConnectProxmox, action_root.join('connect_proxmox')
		autoload :GetNodeList, action_root.join('get_node_list')
		autoload :SelectNode, action_root.join('select_node')
		autoload :ReadState, action_root.join('read_state')
		autoload :IsCreated, action_root.join('is_created')
		autoload :IsStopped, action_root.join('is_stopped')
		autoload :MessageAlreadyRunning, action_root.join('message_already_running')
		autoload :MessageAlreadyStopped, action_root.join('message_already_stopped')
		autoload :MessageNotCreated, action_root.join('message_not_created')
		autoload :MessageNotRunning, action_root.join('message_not_running')
		autoload :MessageFileNotFound, action_root.join('message_file_not_found')
		autoload :MessageUploadServerError, action_root.join('message_upload_server_error')
		autoload :CreateVm, action_root.join('create_vm')
		autoload :StartVm, action_root.join('start_vm')
		autoload :StopVm, action_root.join('stop_vm')
		autoload :ShutdownVm, action_root.join('shutdown_vm')
		autoload :DestroyVm, action_root.join('destroy_vm')
		autoload :CleanupAfterDestroy, action_root.join('cleanup_after_destroy')
		autoload :ReadSSHInfo, action_root.join('read_ssh_info')
		autoload :SyncFolders, action_root.join('sync_folders')
		autoload :UploadTemplateFile, action_root.join('upload_template_file')
		autoload :UploadIsoFile, action_root.join('upload_iso_file')

	end
end
end
