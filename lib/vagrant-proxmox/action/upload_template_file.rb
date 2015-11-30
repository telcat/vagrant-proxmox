module VagrantPlugins
	module Proxmox
		module Action

			# This action uploads a template file into the local storage of a given node
			class UploadTemplateFile < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::template_file_upload'
				end

				def call env
					env[:result] = :ok
					config = env[:machine].provider_config
					if config.openvz_template_file
						env[:result] = upload_file env, config.openvz_template_file, config.replace_openvz_template_file
					end
					next_action env
				end

				private
				def upload_file env, filename, replace
					if File.exist? filename
						begin
							connection(env).upload_file(filename, content_type: 'vztmpl', node: env[:proxmox_selected_node], storage: 'local', replace: replace)
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