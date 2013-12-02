module VagrantPlugins
	module Proxmox
		module Action

			class ReadSSHInfo < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					env[:machine_ssh_info] = get_machine_ip_address(env).try do |ip_address|
						{host: ip_address, port: env[:machine].config.ssh.guest_port}
					end
					next_action env
				end

			end

		end
	end
end
