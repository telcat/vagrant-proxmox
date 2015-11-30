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
						env[:machine_state_id] =
							if env[:machine].id
								node, vm_id = env[:machine].id.split '/'
								env[:proxmox_connection].get_vm_state vm_id
							else
								:not_created
							end
						next_action env
					rescue => e
						raise Errors::CommunicationError, error_msg: e.message
					end

				end

			end

		end
	end
end
