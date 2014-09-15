module VagrantPlugins
	module Proxmox
		module Action

			# This action shuts down the Proxmox virtual machine in env[:machine]
			class ShutdownVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::shutdown_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.shut_down_vm')
					begin
						node, vm_id = env[:machine].id.split '/'
						exit_status = connection(env).shutdown_vm vm_id
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMShutdownError, proxmox_exit_status: e.message
					end
					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
