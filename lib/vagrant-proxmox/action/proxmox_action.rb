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
					config = env[:machine].provider_config
					if config.vm_type == :qemu
						env[:machine].config.vm.networks.select { |type, _| type == :forwarded_port }.first[1][:host_ip] rescue nil
					else
						env[:machine].config.vm.networks.select { |type, _| type == :public_network }.first[1][:ip] rescue nil
					end
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
