module VagrantPlugins
	module Proxmox
		module Action

			class ProxmoxAction

				protected
				def next_action env
					@app.call env
				end

				protected
				def get_machine_ip_address env
					env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:ip] rescue nil
				end
                
                protected
                def get_machine_interface_name env
                    env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:interface] rescue nil
                end
                
                protected
                def get_machine_bridge_name env
                    env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:bridge] rescue nil
                end
                
                protected
                def get_machine_gw_ip env
                    env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:gw] rescue nil
                end

				protected
				def get_machine_macaddress env
					env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:macaddress] rescue nil
				end

				protected
				def connection env
					env[:proxmox_connection]
				end

			end

		end
	end
end
