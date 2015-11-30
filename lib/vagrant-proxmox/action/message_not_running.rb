module VagrantPlugins
	module Proxmox
		module Action

			class MessageNotRunning < ProxmoxAction

				def initialize app, env
					@app = app
				end

 				def call env
					env[:ui].info I18n.t('vagrant_proxmox.errors.vm_not_running')
					next_action env
				end

			end

		end
	end
end
