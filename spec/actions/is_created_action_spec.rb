require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::IsCreated do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

	subject { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		before{allow(env[:machine].provider).to receive(:state).and_return(Vagrant::MachineState.new nil, nil, nil)}

		it_behaves_like 'a proxmox action call'

		context 'when the machine is stopped' do
			before do
				allow(env[:machine].provider).to receive(:state).and_return(Vagrant::MachineState.new :stopped, '', '')
				subject.call env
			end
			specify { env[:result].should == true }
		end

		context 'when the machine is not created' do
			before do
				allow(env[:machine].provider).to receive(:state).and_return(Vagrant::MachineState.new :not_created, '', '')
				subject.call env
			end
			specify { env[:result].should == false }
		end

	end

end
