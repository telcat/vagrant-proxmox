class VagrantUIMock

	class << self
		attr_accessor :logging
	end

	def initialize
		reset!
	end

	def reset!
		@messages = []
		@answers = []
	end

	def scope _
		return self
	end

	def message_not_occurred_error_message message
		<<ERROR_MESSAGE
The expected message

#{message.inspect}

was not seen.

The following messages were printed:

#{@messages.join "\n"}

ERROR_MESSAGE
	end

	def expect_message message
		unless @messages.find { |m| message === m }
			raise message_not_occurred_error_message message
		end
	end

	def add_answer text
		@answers << text
	end

	def ask *args
		@answers.shift
	end

	def method_missing _, *args
		if VagrantUIMock.logging
			puts "Vagrant message: '#{args.first}'"
		end
		@messages << args.first
	end
end

def expect_vagrant_ui_message message
	@ui.expect_message message
end

def stub_ui_input text
	@ui.add_answer text
end