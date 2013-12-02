module VagrantPlugins
	module Proxmox
		module Action

			# This action creates a new virtual machine on the Proxmox server and
			# stores its node and vm_id env[:machine].id
			class CreateVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::create_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.creating_vm')
					config = env[:machine].provider_config
					node = env[:proxmox_nodes].sample[:node]
					vm_id = nil

					begin
						retryable(tries: config.task_timeout,
						          sleep: config.task_status_check_interval) do
							vm_id = get_free_vm_id env
							params = {vmid: vm_id,
							          ostemplate: config.os_template,
							          hostname: env[:machine].config.vm.hostname || env[:machine].name.to_s,
							          password: 'vagrant',
							          memory: config.vm_memory,
							          description: "#{config.vm_name_prefix}#{env[:machine].name}"}
							get_machine_ip_address(env).try { |ip_address| params[:ip_address] = ip_address }

							response = RestClient.post "#{config.endpoint}/nodes/#{node}/openvz", params,
							                           {CSRFPreventionToken: env[:proxmox_csrf_prevention_token],
							                            cookies: {PVEAuthCookie: env[:proxmox_ticket]}}
							exit_status = wait_for_completion parse_task_id(response), node, env, 'vagrant_proxmox.errors.create_vm_timeout'
							exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
						end
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMCreationError, proxmox_exit_status: e.message
					end

					env[:machine].id = "#{node}/#{vm_id}"

					env[:ui].info I18n.t('vagrant_proxmox.done')
					next_action env
				end

				private
				def get_free_vm_id env
					response = RestClient.get "#{env[:machine].provider_config.endpoint}/cluster/resources?type=vm", {cookies: {PVEAuthCookie: env[:proxmox_ticket]}}
					json_response = JSON.parse response.to_s, symbolize_names: true

					allowed_vm_ids = env[:machine].provider_config.vm_id_range.to_set
					used_vm_ids = json_response[:data].map { |vm| vm[:vmid] }
					free_vm_ids = (allowed_vm_ids - used_vm_ids).sort
					free_vm_ids.empty? ? raise(VagrantPlugins::Proxmox::Errors::NoVmIdAvailable) : free_vm_ids.first
				end

			end

		end
	end
end
