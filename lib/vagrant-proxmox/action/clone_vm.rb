module VagrantPlugins
	module Proxmox
		module Action

			# This action clones from a qemu template on the Proxmox server and
			# stores its node and vm_id env[:machine].id
			class CloneVm < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::clone_vm'
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.cloning_vm')
					config = env[:machine].provider_config

					node = env[:proxmox_selected_node]
					vm_id = nil
					template_vm_id = nil

					begin
						template_vm_id = connection(env).get_qemu_template_id(config.qemu_template)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMCloneError, proxmox_exit_status: e.message
					end
	
					begin
						vm_id = connection(env).get_free_vm_id
						params = create_params_qemu(config, env, vm_id, template_vm_id)
						exit_status = connection(env).clone_vm node: node, vm_type: config.vm_type, params: params
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMCloneError, proxmox_exit_status: e.message
					end

					env[:machine].id = "#{node}/#{vm_id}"

					env[:ui].info I18n.t('vagrant_proxmox.done')
					next_action env
				end

				private
				def create_params_qemu(config, env, vm_id, template_vm_id)
					# without network, which will added in ConfigClonedVm
					{vmid: template_vm_id,
					 newid: vm_id,
					 name: env[:machine].config.vm.hostname || env[:machine].name.to_s,
					 description: "#{config.vm_name_prefix}#{env[:machine].name}"}
				end

			end
		end
	end
end
