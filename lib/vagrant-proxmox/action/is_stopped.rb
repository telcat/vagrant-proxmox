module VagrantPlugins
  module Proxmox
    module Action

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
