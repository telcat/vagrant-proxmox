module VagrantPlugins
	module Proxmox

		module ApiError

			class InvalidCredentials < StandardError
			end

			class ConnectionError < StandardError
			end

			class NotImplemented < StandardError
			end

			class ServerError < StandardError
			end

			class UnauthorizedError < StandardError
			end

		end
	end
end
