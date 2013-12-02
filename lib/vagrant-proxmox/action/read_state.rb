module VagrantPlugins
	module Proxmox
		module Action

			# This action reads the state of a Proxmox virtual machine and stores it
			# in env[:machine_state_id].
			class ReadState < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::read_state'
				end

				def call env
					begin
						if env[:machine].id
							node, vm_id = env[:machine].id.split '/'
							endpoint = env[:machine].provider_config.endpoint
							response = RestClient.get "#{endpoint}/nodes/#{node}/openvz/#{vm_id}/status/current",
																				{cookies: {PVEAuthCookie: env[:proxmox_ticket]}}
							states = {'running' => :running,
												'stopped' => :stopped}
							env[:machine_state_id] = states[JSON.parse(response.to_s)['data']['status']]
						else
							env[:machine_state_id] = :not_created
						end
					rescue RestClient::InternalServerError
						env[:machine_state_id] = :not_created
					end
					next_action env
				end

			end

		end
	end
end
