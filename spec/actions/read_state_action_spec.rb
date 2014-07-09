require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe VagrantPlugins::Proxmox::Action::ReadState do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox), proxmox_connection: connection} }
		let(:node) { 'localhost' }
		let(:vm_id) { '100' }
		let(:machine_id) { "#{node}/#{vm_id}" }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before do
			env[:machine].stub(:id) { machine_id }
			connection.stub :get_vm_state
		end

		describe '#call' do

			it_behaves_like 'a proxmox action call'

			it 'should store the machine state in env[:machine_state_id]' do
				connection.should_receive(:get_vm_state).and_return :running
				action.call env
				env[:machine_state_id].should == :running
			end

			it 'should call get_vm_state with the node and vm_id' do
				connection.should_receive(:get_vm_state).with node: node, vm_id: vm_id
				action.call env
			end

			context 'when no machine id is defined' do
				let(:machine_id) { nil }
				it 'should [:machine_state_id] to :not_created' do
					action.call env
					env[:machine_state_id].should == :not_created
				end
			end

			context 'when the server communication fails' do
				before { connection.stub(:get_vm_state).and_raise ApiError::ConnectionError }
				it 'should raise an error' do
					expect { action.call env }.to raise_error Errors::CommunicationError
				end
			end

		end

	end

end
