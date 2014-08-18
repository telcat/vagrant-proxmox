require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe VagrantPlugins::Proxmox::Action::SelectNode do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://proxmox.example.com/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_connection: connection, proxmox_nodes: nodes} }
		let(:nodes) { ['node1', 'node2'] }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

			before do
				allow(nodes).to receive(:sample).and_return 'node2'
			end

			it_behaves_like 'a proxmox action call'

			it 'randomly selects a node from the list of available nodes' do
				action.call env
				expect(env[:proxmox_selected_node]).to eq('node2')
			end

		end

	end

end
