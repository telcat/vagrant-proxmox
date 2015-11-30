module VagrantPlugins
	module Proxmox
		module Action

			class MessageAlreadyRunning < ProxmoxAction

				def initialize app, env
					@app = app
				end

				def call env
					env[:ui].info I18n.t('vagrant_proxmox.already_running')
					next_action env
				end

			end

		end
	end
end
