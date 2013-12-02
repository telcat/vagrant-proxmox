module VagrantPlugins
	module Proxmox
		module Action

			class ProxmoxAction

				protected
				def next_action env
					@app.call env
				end

				protected
				def parse_task_id proxmox_response
					JSON.parse(proxmox_response.to_s, symbolize_names: true)[:data]
				end

				# Wait for the completion of the proxmox task with the given upid.
				protected
				def wait_for_completion task_upid, node, env, timeout_message
					begin
						retryable(on: VagrantPlugins::Proxmox::ProxmoxTaskNotFinished,
											tries: env[:machine].provider_config.task_timeout,
											sleep: env[:machine].provider_config.task_status_check_interval) do
							exit_status = get_task_exitstatus task_upid, node, env
							exit_status.nil? ? raise(VagrantPlugins::Proxmox::ProxmoxTaskNotFinished) : exit_status
						end
					rescue VagrantPlugins::Proxmox::ProxmoxTaskNotFinished
						raise Errors::Timeout.new timeout_message
					end
				end

				protected
				def get_machine_ip_address env
					env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:ip] rescue nil
				end

				private
				def get_task_exitstatus task_upid, node, env
					response = RestClient.get "#{env[:machine].provider_config.endpoint}/nodes/#{node}/tasks/#{task_upid}/status", {cookies: {PVEAuthCookie: env[:proxmox_ticket]}}
					parse_task_id(response)[:exitstatus]
				end

			end

		end
	end
end
