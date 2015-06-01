module VagrantPlugins
	module Proxmox
		module Action

			# This action uploads a iso file into the local storage a given node
			class UploadIsoFile < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::iso_file_upload'
				end

				def call env
					env[:result] = :ok
					config = env[:machine].provider_config
					if config.qemu_iso_file
						env[:result] = upload_file env, config.qemu_iso_file, config.replace_qemu_iso_file
					end
					next_action env
				end

				private
				def upload_file env, filename, replace
					if File.exist? filename
						begin
							connection(env).upload_file(filename, content_type: 'iso', node: env[:proxmox_selected_node], storage: 'local', replace: replace)
							:ok
						rescue
							:server_upload_error
						end
					else
						:file_not_found
					end
				end
			end
		end
	end
end