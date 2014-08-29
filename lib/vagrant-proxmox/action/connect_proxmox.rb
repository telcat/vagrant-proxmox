module VagrantPlugins
	module Proxmox
		module Action

			# This action connects to the Proxmox server and stores the
			# connection in env[:proxmox_connection]
			class ConnectProxmox < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::connect_proxmox'
				end

				def call env
					begin
						config = env[:machine].provider_config
						connection = Connection.new config.endpoint,
																				vm_id_range: config.vm_id_range,
																				task_timeout: config.task_timeout,
																				task_status_check_interval: config.task_status_check_interval,
																				imgcopy_timeout: config.imgcopy_timeout
						connection.login username: config.user_name, password: config.password
						env[:proxmox_connection] = connection
					rescue => e
						raise Errors::CommunicationError, error_msg: e.message
					end
					next_action env
				end

			end
		end
	end
end
