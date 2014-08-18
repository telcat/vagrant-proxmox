require 'timecop'

class Fixnum

	def self.time_interval_converter unit, factor
		define_method(unit) do
			TimeInterval.new self * factor, factor, unit
		end
	end

	time_interval_converter :second, 1
	time_interval_converter :seconds, 1
	time_interval_converter :minute, 60
	time_interval_converter :minutes, 60
	time_interval_converter :hour, 3600
	time_interval_converter :hours, 3600
	time_interval_converter :day, 86400
	time_interval_converter :days, 86400

end

class TimeInterval

	attr_reader :unit
	attr_reader :factor

	def initialize value, factor, unit
		@value = value.to_i
		@factor = factor
		@unit = unit
	end

	def clone_with_value value
		TimeInterval.new value, @factor, @unit
	end

	def inspect
		to_s
	end

	def to_s
		("%.2f #{@unit}" % (in_units)).sub /\.00/, ''
	end

	def in_seconds
		@value
	end

	def in_units
		@value.to_f / @factor
	end

	def < other
		in_seconds < other.in_seconds
	end

end

class Timecop

	class << self

		alias :old_freeze :freeze

		def freeze *args, &block
			args << Time.local(5555) if args.empty?
			@frozen_time = args[0]
			old_freeze *args, &block
		end

		def frozen_time
			@frozen_time
		end

		def has_travelled? interval
			@frozen_time.to_i + interval.in_seconds == Time.now.to_i
		end

	end
end

RSpec::Matchers.define :have_elapsed do |expected|
	match do
		Timecop.has_travelled? expected
	end
	failure_message do
		result = expected.clone_with_value Time.now - Timecop.frozen_time
		"expected current time to be #{expected} later, but #{result < expected ? 'only' : 'already'} #{result} elapsed"
	end
end