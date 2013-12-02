require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::StopVm do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
							 proxmox_nodes: [{node: 'localhost'}],
							 ui: double('ui').as_null_object} }

	subject { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		before do
			env[:machine].id = 'localhost/100'
			allow(RestClient).to receive(:post).and_return({data: 'task_id'}.to_json)
			allow(RestClient).to receive(:get).and_return({data: {exitstatus: 'OK'}}.to_json)
		end

		it_behaves_like 'a proxmox action call'
		it_behaves_like 'a blocking proxmox action'

		it 'should send a post request that stops the openvz container' do
			RestClient.should_receive(:post).with('https://your.proxmox.server/api2/json/nodes/localhost/openvz/100/status/stop', nil, anything)
			subject.call env
		end

		it 'should print a message to the user interface' do
			env[:ui].should_receive(:info).with 'Stopping the virtual machine...'
			env[:ui].should_receive(:info).with 'Done!'
			subject.call env
		end

	end

end
