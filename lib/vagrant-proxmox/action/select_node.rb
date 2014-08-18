module VagrantPlugins
	module Proxmox
		module Action

			# This action reads the state of a Proxmox virtual machine and stores it
			# in env[:machine_state_id].
			class SelectNode < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::select_node'
				end

				def call env
					env[:proxmox_selected_node] = env[:proxmox_nodes].sample
					next_action env
				end

			end

		end
	end
end
