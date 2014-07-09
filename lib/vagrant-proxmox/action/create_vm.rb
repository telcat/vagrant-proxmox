module VagrantPlugins
	module Proxmox
		module Action

			# This action creates a new virtual machine on the Proxmox server and
			# stores its node and vm_id env[:machine].id
			class CreateVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::create_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.creating_vm')
					config = env[:machine].provider_config
					node = env[:proxmox_nodes].sample
					vm_id = nil

					begin
						vm_id = connection(env).get_free_vm_id
						params = {vmid: vm_id,
											ostemplate: config.os_template,
											hostname: env[:machine].config.vm.hostname || env[:machine].name.to_s,
											password: 'vagrant',
											memory: config.vm_memory,
											description: "#{config.vm_name_prefix}#{env[:machine].name}"}
						params[:ip_address] = get_machine_ip_address(env) if get_machine_ip_address(env)

						exit_status = connection(env).create_vm node: node, params: params
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMCreateError, proxmox_exit_status: e.message
					end

					env[:machine].id = "#{node}/#{vm_id}"

					env[:ui].info I18n.t('vagrant_proxmox.done')
					next_action env
				end

			end

		end
	end
end
