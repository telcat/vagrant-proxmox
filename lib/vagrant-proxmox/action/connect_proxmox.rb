module VagrantPlugins
	module Proxmox
		module Action

			# This action connects to the Proxmox server and stores the access ticket
			# and csrf prevention token in env[:proxmox_ticket] and
			# env[:proxmox_csrf_prevention_token].
			class ConnectProxmox < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::connect_proxmox'
				end

				def call env
					config = env[:machine].provider_config
					response = RestClient.post "#{config.endpoint}/access/ticket",
					                           username: config.user_name, password: config.password
					begin
						json_response = JSON.parse response.to_s, symbolize_names: true
						env[:proxmox_ticket] = json_response[:data][:ticket]
						env[:proxmox_csrf_prevention_token] = json_response[:data][:CSRFPreventionToken]
					rescue => e
						raise Errors::CommunicationError, error_msg: e.message
					end
					next_action env
				end

			end

		end
	end
end
