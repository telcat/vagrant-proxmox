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

					node = env[:proxmox_selected_node]
					vm_id = nil

					begin
						vm_id = connection(env).get_free_vm_id
						params = create_params_openvz(config, env, vm_id) if config.vm_type == :openvz
						if config.vm.clone 
							@logger.info("= Cloning")
							params = create_params_qemu_clone(config, env, vm_id, node) if config.vm_type == :qemu
							@logger.debug("== Params: #{params}")
							exit_status = connection(env).clone_vm node: node, vm_type: config.vm_type, params: params, src_vm_id: config.src_vm_id
							@logger.debug("== Exit status #{exit_status}")
						else
							@logger.info("= Creating")
						params = create_params_qemu(config, env, vm_id) if config.vm_type == :qemu
						exit_status = connection(env).create_vm node: node, vm_type: config.vm_type, params: params
						end

						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)

						# Configure MAC address of clone
						@logger.info("= Getting config")
						digest = connection(env).get_config node: node, vm_type: config.vm_type, vm_id: vm_id

						@logger.info("= Setting MAC Address")
						params2 = create_params_config(config, env, digest)
						exit_status = connection(env).config_vm node: node, vm_type: config.vm_type, params: params2, vm_id: vm_id
						
						exit_status == 'OK' ? exit_status : raise(VagrantPlugins::Proxmox::Errors::ProxmoxTaskFailed, proxmox_exit_status: exit_status)
					rescue StandardError => e
						raise VagrantPlugins::Proxmox::Errors::VMCreateError, proxmox_exit_status: e.message
					end

					env[:machine].id = "#{node}/#{vm_id}"

					env[:ui].info I18n.t('vagrant_proxmox.done')
					next_action env
				end

				private
				def create_params_qemu_clone(config, env, vm_id, node)
					{newid: vm_id,
					 target: "pve",
					 full: 1,
					 storage: "local",
					 format: "raw",
					 name: env[:machine].config.vm.hostname || env[:machine].name.to_s,
					 pool: "vagrant"
					}
				end

				private
				def create_params_config(config, env, digest)
					macaddress = env[:machine].config.vm.networks.select { |type, _| type == :public_network or type == :private_network }.first[1][:macaddress] rescue nil
					network = "#{config.qemu_nic_model}=#{macaddress},bridge=#{config.qemu_bridge}"
					{net0: network,
					 digest: digest
					}
				end

				private
				def create_params_qemu(config, env, vm_id)
					network = "#{config.qemu_nic_model},bridge=#{config.qemu_bridge}"
					network = "#{config.qemu_nic_model}=#{get_machine_macaddress(env)},bridge=#{config.qemu_bridge}" if get_machine_macaddress(env)
					{vmid: vm_id,
					 name: env[:machine].config.vm.hostname || env[:machine].name.to_s,
					 ostype: config.qemu_os,
					 ide2: "#{config.qemu_iso},media=cdrom",
					 sata0: "#{config.qemu_storage}:#{config.qemu_disk_size},format=qcow2",
					 sockets: config.qemu_sockets,
					 cores: config.qemu_cores,
					 memory: config.vm_memory,
					 net0: network,
					 description: "#{config.vm_name_prefix}#{env[:machine].name}"}
				end

				private
				def create_params_openvz(config, env, vm_id)
					{vmid: vm_id,
					 ostemplate: config.openvz_os_template,
					 hostname: env[:machine].config.vm.hostname || env[:machine].name.to_s,
					 password: 'vagrant',
					 memory: config.vm_memory,
					 description: "#{config.vm_name_prefix}#{env[:machine].name}"}
					.tap do |params|
						params[:ip_address] = get_machine_ip_address(env) if get_machine_ip_address(env)
					end
				end
			end
		end
	end
end
