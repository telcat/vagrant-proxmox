module VagrantPlugins
	module Proxmox
		module Action

			# This action starts the Proxmox virtual machine in env[:machine]
			class StartVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::start_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.starting_vm')
					begin
						node, vm_id = env[:machine].id.split '/'
						exit_status = connection(env).start_vm node: node, vm_id: vm_id
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMStartError, proxmox_exit_status: e.message
					end

					env[:ui].info I18n.t('vagrant_proxmox.done')

					env[:ui].info I18n.t('vagrant_proxmox.waiting_for_ssh_connection')
					loop do
						# If we're interrupted then just back out
						break if env[:interrupted]
						break if env[:machine].communicate.ready?
						sleep env[:machine].provider_config.task_status_check_interval
					end
					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
