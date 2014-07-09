module VagrantPlugins
	module Proxmox
		module Action

			# This action gets a list of all the nodes e.g. ['node1', 'node2'] of
			# a Proxmox server cluster and stores it under env[:proxmox_nodes]
			class GetNodeList < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					begin
						env[:proxmox_nodes] = env[:proxmox_connection].get_node_list
						next_action env
					rescue => e
						raise Errors::CommunicationError, error_msg: e.message
					end
				end

			end

		end
	end
end
