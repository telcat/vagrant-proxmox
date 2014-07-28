require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::ReadSSHInfo do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

	subject(:action) { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		it_behaves_like 'a proxmox action call'

		context 'when no ip address is configured' do
			it 'should write no ssh info into env[:machine_ssh_info]' do
				action.call env
				expect(env[:machine_ssh_info]).to eq(nil)
			end
		end

		context 'when an ip address is configured' do
			before { allow(env[:machine].config.vm).to receive(:networks) { [[:public_network, {ip: '127.0.0.1'}]] } }
			it 'should write the ssh info into env[:machine_ssh_info]' do
				action.call env
				expect(env[:machine_ssh_info]).to eq({host: '127.0.0.1', port: 22})
			end
		end

	end

end
