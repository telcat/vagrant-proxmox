module VagrantPlugins
	module Proxmox
		module Action

			# This action shuts down a Proxmox virtual machine.
			class ShutdownVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::shutdown_vm'
				end

				def call env
					endpoint = env[:machine].provider_config.endpoint
					node, vm_id = env[:machine].id.split '/'
					env[:ui].info I18n.t('vagrant_proxmox.shut_down_vm')
					response = RestClient.post "#{endpoint}/nodes/#{node}/openvz/#{vm_id}/status/shutdown", nil,
																		 {CSRFPreventionToken: env[:proxmox_csrf_prevention_token],
																		  cookies: {PVEAuthCookie: env[:proxmox_ticket]}}

					wait_for_completion parse_task_id(response), node, env, 'vagrant_proxmox.errors.shutdown_vm_timeout'
					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
