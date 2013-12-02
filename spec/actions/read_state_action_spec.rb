require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::ReadState do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

	subject { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		it_behaves_like 'a proxmox action call'

		context 'when no machine id is defined' do
			specify do
				subject.call env
				env[:machine_state_id].should == :not_created
			end
		end

		context 'when the machine is not created' do
			before { env[:machine].id = 'localhost/100' }
			specify do
				RestClient.should_receive(:get).with('https://your.proxmox.server/api2/json/nodes/localhost/openvz/100/status/current', anything).
						and_raise(RestClient::InternalServerError)
				subject.call env
				env[:machine_state_id].should == :not_created
			end
		end

		context 'when the machine is stopped' do
			before { env[:machine].id = 'localhost/100' }
			specify do
				RestClient.should_receive(:get).with('https://your.proxmox.server/api2/json/nodes/localhost/openvz/100/status/current', anything).
						and_return({data: {status: 'stopped'}}.to_json)
				subject.call env
				env[:machine_state_id].should == :stopped
			end
		end

		context 'when the machine is running' do
			before { env[:machine].id = 'localhost/100' }
			specify do
				RestClient.should_receive(:get).with('https://your.proxmox.server/api2/json/nodes/localhost/openvz/100/status/current', anything).
						and_return({data: {status: 'running'}}.to_json)
				subject.call env
				env[:machine_state_id].should == :running
			end
		end

	end

end
