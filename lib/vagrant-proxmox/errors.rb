module VagrantPlugins
	module Proxmox

		class ProxmoxTaskNotFinished < Exception
		end

		module Errors

			class VagrantProxmoxError < Vagrant::Errors::VagrantError
				error_namespace 'vagrant_proxmox.errors'
			end

			class ProxmoxTaskFailed < VagrantProxmoxError
				error_key :proxmox_task_failed
			end

			class CommunicationError < VagrantProxmoxError
				error_key :communication_error
			end

			class Timeout < VagrantProxmoxError
				error_key :timeout
			end

			class NoVmIdAvailable < VagrantProxmoxError
				error_key :no_vm_id_available
			end

			class VMCreationError < VagrantProxmoxError
				error_key :vm_creation_error
			end

			class RsyncError < VagrantProxmoxError
				error_key :rsync_error
			end

		end
	end
end
