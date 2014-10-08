module VagrantPlugins::Proxmox
	module RequiredParameters

		def required keyword

			fail ArgumentError, "missing keyword: #{keyword}", caller
		end
	end
end