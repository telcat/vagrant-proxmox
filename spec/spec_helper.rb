if ENV['RUN_WITH_COVERAGE']
	require 'simplecov'
	require 'simplecov-rcov'
	SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
		SimpleCov::Formatter::HTMLFormatter,
		SimpleCov::Formatter::RcovFormatter,
	]
	SimpleCov.start do
		add_filter '/dummy_box/Vagrantfile'
		add_filter '/spec/'
		add_filter '/lib/sanity_checks.rb'
	end
end

require 'vagrant-proxmox'
require 'spec_helpers/common_helpers'
require 'active_support/core_ext/string'
require 'timecop'
require 'spec_helpers/time_helpers'

RSpec.configure do |config|

	config.before(:suite) do
		add_dummy_box
	end
	config.after(:suite) do
		remove_dummy_box
	end
	config.after(:each) do
		FileUtils.rm_r '.vagrant', force: true
	end

	config.before(:each, :need_box) do
		up_local_box
	end

end

if ENV['COVERAGE']
	require 'simplecov'
	require 'simplecov-rcov'
	SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
		SimpleCov::Formatter::HTMLFormatter,
		SimpleCov::Formatter::RcovFormatter,
	]
	SimpleCov.start
end