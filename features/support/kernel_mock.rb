module KernelMock

	class << self

		def reset! example_group
			@system_calls = []
			example_group.allow(Kernel).to example_group.receive(:exec) do |*params|
				@system_calls << params.join(' ')
			end
		end

		def expect_system_call call
			unless @system_calls.find { |c| call === c }
				raise expected_system_call_not_called_error_message call
			end
		end

		def expected_system_call_not_called_error_message call
			<<ERROR_MESSAGE
The expected Kernel system call

#{call.inspect}

was not called.

The following Kernel system calls were invoked:

#{@system_calls.join "\n"}

ERROR_MESSAGE
		end

	end

end

def expect_kernel_system_call call
	KernelMock.expect_system_call call
end
