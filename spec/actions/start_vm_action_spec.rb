require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::StartVm do

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
			allow(env[:machine].communicate).to receive(:ready?).and_return true
		end

		it_behaves_like 'a proxmox action call'
		it_behaves_like 'a blocking proxmox action'

		it 'should send a post request that starts the openvz container' do
			RestClient.should_receive(:post).with('https://your.proxmox.server/api2/json/nodes/localhost/openvz/100/status/start', nil, anything)
			subject.call env
		end

		it 'should print a message to the user interface' do
			env[:ui].should_receive(:info).with 'Starting the virtual machine...'
			env[:ui].should_receive(:info).with 'Done!'
			env[:ui].should_receive(:info).with 'Waiting for SSH connection...'
			env[:ui].should_receive(:info).with 'Done!'
			subject.call env
		end

		it 'should periodically call env[:machine].communicate.ready? to check for ssh access' do
			expect(env[:machine].communicate).to receive(:ready?).and_return false
			expect(subject).to receive(:sleep).with 1
			expect(env[:machine].communicate).to receive(:ready?).and_return true
			subject.call env
		end

	end

end
