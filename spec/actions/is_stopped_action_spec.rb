require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::IsStopped do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

	subject(:action) { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		before { allow(env[:machine].provider).to receive_messages :state => Vagrant::MachineState.new(nil, nil, nil) }

		it_behaves_like 'a proxmox action call'

		context 'when the machine is stopped' do
			before do
				allow(env[:machine].provider).to receive_messages :state => Vagrant::MachineState.new(:stopped, '', '')
				action.call env
			end
			specify { expect(env[:result]).to eq(true) }
		end

		context 'when the machine is running' do
			before do
				allow(env[:machine].provider).to receive_messages :state => Vagrant::MachineState.new(:running, '', '')
				action.call env
			end
			specify { expect(env[:result]).to eq(false) }
		end
	end

end
