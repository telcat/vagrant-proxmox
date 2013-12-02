module VagrantPlugins
	module Proxmox
		module Action

			class DestroyVm < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.destroying_vm')
					node, vm_id = env[:machine].id.split '/'
					endpoint = env[:machine].provider_config.endpoint
					response = RestClient.delete "#{endpoint}/nodes/#{node}/openvz/#{vm_id}",
																		 {CSRFPreventionToken: env[:proxmox_csrf_prevention_token],
																		  cookies: {PVEAuthCookie: env[:proxmox_ticket]}}

					wait_for_completion parse_task_id(response), node, env, 'vagrant_proxmox.errors.destroy_vm_timeout'
					env[:ui].info I18n.t('vagrant_proxmox.done')

					next_action env
				end

			end

		end
	end
end
