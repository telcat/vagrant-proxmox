require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::MessageAlreadyStopped do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {ui: double('ui').as_null_object} }

	subject { described_class.new(-> (_) {}, environment) }

	before { VagrantPlugins::Proxmox::Plugin.setup_i18n }

	describe '#call' do

		it_behaves_like 'a proxmox action call'

		specify do
			expect(env[:ui]).to receive(:info).with 'The virtual machine is already stopped'
			subject.call env
		end
	end

end
