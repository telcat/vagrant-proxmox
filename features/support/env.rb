require 'vagrant-proxmox'
require 'cucumber/rspec/doubles'
require 'rspec/matchers'
require 'active_support/core_ext/string'
require 'webmock/cucumber'
require_relative 'vagrant_process_mock'
require_relative 'machine_helper'
require_relative 'template_helper'
require_relative 'file_helper'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib')

add_dummy_box

at_exit do
	remove_dummy_box
end

Before do
	@ui = VagrantUIMock.new
	@original_rubylib = ENV['RUBYLIB']
	ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
	FileUtils.rm_r '.vagrant', force: true
	VagrantSSHMock.reset! self
	clear_tempfile_list
	CommunicatorMock.ssh_enabled = true
end

After do
	ENV['RUBYLIB'] = @original_rubylib
	remove_all_tempfiles
end
