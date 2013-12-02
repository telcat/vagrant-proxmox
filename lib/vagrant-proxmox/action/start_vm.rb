module VagrantPlugins
	module Proxmox
		module Action

			# This action starts a Proxmox virtual machine.
			class StartVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::start_vm'
				end

				def call env
					endpoint = env[:machine].provider_config.endpoint
					node, vm_id = env[:machine].id.split '/'
					env[:ui].info I18n.t('vagrant_proxmox.starting_vm')
					response = RestClient.post "#{endpoint}/nodes/#{node}/openvz/#{vm_id}/status/start", nil,
																		 {CSRFPreventionToken: env[:proxmox_csrf_prevention_token],
																		  cookies: {PVEAuthCookie: env[:proxmox_ticket]}}

					wait_for_completion parse_task_id(response), node, env, 'vagrant_proxmox.errors.start_vm_timeout'
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
