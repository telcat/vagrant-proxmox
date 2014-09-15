module VagrantPlugins
	module Proxmox
		module Action

			# This action stops the Proxmox virtual machine in env[:machine]
			class StopVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::stop_vm'
				end

				def call env
					begin
						node, vm_id = env[:machine].id.split '/'
						env[:ui].info I18n.t('vagrant_proxmox.stopping_vm')
						exit_status = connection(env).stop_vm vm_id
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMStopError, proxmox_exit_status: e.message
					end

					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
