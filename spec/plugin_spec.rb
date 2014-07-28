require 'spec_helper'

describe 'Vagrant Proxmox plugin' do

	specify { expect(Vagrant).to have_plugin 'Proxmox' }

	describe 'when vagrant log level is set in ENV[VAGRANT_LOG]' do
		before { ENV['VAGRANT_LOG'] = 'DEBUG' }
		it 'should create a new vagrant proxmox logger ' do
			expect(Log4r::Logger).to receive(:new).with('vagrant_proxmox').and_call_original
			VagrantPlugins::Proxmox::Plugin.setup_logging
		end
	end

end
