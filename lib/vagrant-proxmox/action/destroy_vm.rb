module VagrantPlugins
	module Proxmox
		module Action

			# This action destroys the virtual machine env[:machine]
			class DestroyVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::destroy_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.destroying_vm')

					begin
						node, vm_id = env[:machine].id.split '/'
						exit_status = connection(env).delete_vm node: node, vm_id: vm_id
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMDestroyError, proxmox_exit_status: e.message
					end

					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
