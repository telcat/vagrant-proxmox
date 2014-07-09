module VagrantPlugins
  module Proxmox
    module Action

			# set env[:result] to :stopped
      class IsStopped < ProxmoxAction

        def initialize app, env
          @app = app
        end

				def call env
          env[:result] = env[:machine].state.id == :stopped
					next_action env
				end

			end

    end
  end
end
