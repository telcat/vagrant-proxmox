module VagrantPlugins
	module Proxmox
		module Action

			# This action creates a new virtual machine on the Proxmox server and
			# stores its node and vm_id env[:machine].id
			class AdjustForwardedPortParams < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::adjust_forwarded_port_params'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.adjust_forwarded_port_params')
					config = env[:machine].provider_config
					node = env[:proxmox_selected_node]
					vm_id = nil

					begin
						vm_id = env[:machine].id.split("/").last
						node_ip = env[:proxmox_connection].get_node_ip(node, 'vmbr0')
						env[:machine].config.vm.networks.each do |type, options|
							next if type != :forwarded_port
							if options[:id] == "ssh"
								# Provisioning and vagrant ssh will use this
								# high port of the selected proxmox node
								options[:auto_correct] = false
								options[:host_ip] = node_ip
								options[:host] = sprintf("22%03d", vm_id.to_i).to_i
								env[:machine].config.ssh.host = node_ip
								env[:machine].config.ssh.port = sprintf("22%03d", vm_id.to_i).to_s
								break
							end
						end
					end
					next_action env
				end
			end
		end
	end
end
