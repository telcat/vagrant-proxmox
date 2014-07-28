require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::GetNodeList do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://proxmox.example.com/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox), proxmox_connection: connection} }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

			describe 'proxmox action call' do
				before { allow(connection).to receive_messages get_node_list: [] }
				it_behaves_like 'a proxmox action call'
			end

			it 'should store the node list in env[:proxmox_nodes]' do
				expect(connection).to receive(:get_node_list).and_return ['node1', 'node2']
				action.call env
				expect(env[:proxmox_nodes]).to eq(['node1', 'node2'])
			end

			context 'when the server communication fails' do
				before { allow(connection).to receive(:get_node_list).and_raise ApiError::ConnectionError }
				it 'should raise an error' do
					expect { action.call env }.to raise_error Errors::CommunicationError
				end
			end

		end

	end

end