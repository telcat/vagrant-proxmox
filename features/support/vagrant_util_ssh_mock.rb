require 'vagrant/util/ssh'

module VagrantSSHMock

	class << self

		def reset! example_group
			@system_commands = []
			example_group.allow(Vagrant::Util::SSH).to example_group.receive(:exec) do |ssh_info, opts|
				@system_commands << (opts[:extra_args] || []).join(' ')
			end
		end

		def expect_call command
			unless @system_commands.find { |c| command === c }
				raise expected_command_not_called_error_message command
			end
		end

		def expected_command_not_called_error_message command
			<<ERROR_MESSAGE
The expected Vagrant SSH command

#{command.inspect}

was not called.

The following Vagrant SSH commands were invoked:

#{@system_commands.map { |c| %Q{"#{c}"} }.join "\n"}

ERROR_MESSAGE
		end

	end

end

def expect_vagrant_ssh_command command
	VagrantSSHMock.expect_call command
end
