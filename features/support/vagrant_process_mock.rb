require 'vagrant/util/subprocess'
require 'ostruct'

module Vagrant
	module Util
		class Subprocess
			def self.execute *command, &block
				if VagrantProcessMock.enabled
					VagrantProcessMock.check_call command.join(' '), :local
					OpenStruct.new exit_code: 0, stdout: ''
				else
					new(*command).execute(&block)
				end
			end
		end
	end
end

class CommunicatorMock

	@ssh_enabled = true

	class << self
		attr_accessor :ssh_enabled
	end

	def sudo command, opts=nil, &block
		VagrantProcessMock.check_call command, :remote
	end

	def upload *_
	end

	def execute command, opts=nil, &block
		VagrantProcessMock.check_call command, :remote
	end

	def ready?
		CommunicatorMock.ssh_enabled
	end
end

module Vagrant
	class Machine
		def communicate
			CommunicatorMock.new
		end
	end
end

module VagrantProcessMock

	class << self

		attr_accessor :enabled
		attr_accessor :logging

		def initialize
			reset!
			@enabled = true
			@logging = false
		end

		def reset!
			@stubbed_calls = {local: [], remote: []}
			reset_history!
		end

		def reset_history!
			@calls = {local: [], remote: []}
		end

		def check_call call, type
			if @logging
				puts "Vagrant #{type} call: #{call}"
			end
			@calls[type] << call
			unless @stubbed_calls[type].find { |s| s === call }
				raise unstubbed_call_error_message call, type
			end
		end

		def stub_call call, type
			@stubbed_calls[type] << call
		end

		def expect_call call, type
			unless @calls[type].find { |c| call === c }
				raise expected_call_not_called_error_message call, type
			end
		end

		def expected_call_not_called_error_message call, type
			<<ERROR_MESSAGE
The expected #{type} call

#{call.inspect}

was not called.

The following #{type} calls were invoked:

#{@calls[type].join "\n"}

ERROR_MESSAGE
		end

		def unstubbed_call_error_message call, type
			<<ERROR_MESSAGE
Real #{type} calls are disabled. Unregistered #{type} call:

#{call}

You can stub this #{type} call with the following snippet:

stub_#{type}_vagrant_call '#{call.gsub /'/, "\\\\'"}'

registered #{type} call stubs:

#{@stubbed_calls[type].join "\n"}

ERROR_MESSAGE
		end
	end

end

def stub_local_vagrant_call call
	VagrantProcessMock.stub_call call, :local
end

def stub_remote_vagrant_call call
	VagrantProcessMock.stub_call call, :remote
end

def expect_remote_vagrant_call call
	VagrantProcessMock.expect_call call, :remote
end

def expect_local_vagrant_call call
	VagrantProcessMock.expect_call call, :local
end

VagrantProcessMock.initialize
