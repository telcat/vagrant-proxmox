require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::GetNodeList do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

	subject { described_class.new(-> (_) {}, environment) }

	describe '#call' do

		before {allow(RestClient).to receive(:get).and_return({data: [{node: 'localhost'}]}.to_json)}

		it_behaves_like 'a proxmox action call'

		it 'should store the node list in env[:proxmox_nodes]' do
			RestClient.should_receive(:get).with('https://your.proxmox.server/api2/json/nodes', anything)
			subject.call env
			env[:proxmox_nodes].should == [{node: 'localhost'}]
		end

	end

end
