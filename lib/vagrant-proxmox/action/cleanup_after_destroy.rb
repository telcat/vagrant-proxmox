module VagrantPlugins
	module Proxmox
		module Action

			class CleanupAfterDestroy < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					FileUtils.rm_rf ".vagrant/machines/#{env[:machine].name}/proxmox"
					next_action env
				end

			end

		end
	end
end
