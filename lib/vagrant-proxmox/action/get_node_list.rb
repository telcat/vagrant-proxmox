module VagrantPlugins
	module Proxmox
		module Action

			# This action gets a list of all the nodes of a Proxmox server cluster
			# and stores it under env[:proxmox_nodes]
			class GetNodeList < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					endpoint = env[:machine].provider_config.endpoint
					response = RestClient.get "#{endpoint}/nodes", {cookies: {PVEAuthCookie: env[:proxmox_ticket]}}
					env[:proxmox_nodes] = JSON.parse(response.to_s, symbolize_names: true)[:data]
					next_action env
				end

			end

		end
	end
end
