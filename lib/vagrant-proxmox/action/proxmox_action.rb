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
					env[:machine].config.vm.networks.select { |type, _| type == :public_network or type == :private_network}.first[1][:ip] rescue nil
				end

				protected
				def get_machine_macaddress env
					env[:machine].config.vm.networks.select { |type, _| type == :public_network or type == :private_network}.first[1][:macaddress] rescue nil
				end

				protected
				def connection env
					env[:proxmox_connection]
				end

			end

		end
	end
end
