require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe VagrantPlugins::Proxmox::Action::SelectNode do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://proxmox.example.com/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_connection: connection, proxmox_nodes: nodes} }
		let(:nodes) { ['node1', 'node2', 'selected_node'] }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

      it_behaves_like 'a proxmox action call'

      context "when no selected_node is specified in the configuration" do
        it 'randomly selects a node from the list of available nodes' do
          expect(nodes).to receive(:sample).and_return 'node2'
          action.call env
          expect(env[:proxmox_selected_node]).to eq('node2')
        end
      end

      context "when a specific node is specified in the configuration" do

        context "when this node is included in the nodes list" do
          before do
            env[:machine].provider_config.selected_node = 'selected_node'
          end

          it 'selects the selected_node' do
            expect(nodes).not_to receive(:sample)
            action.call env
            expect(env[:proxmox_selected_node]).to eq('selected_node')
          end
        end

        context "when this node is not included in the nodes list" do
          before do
            env[:machine].provider_config.selected_node = 'invalid_node'
          end

          it 'should raise an error' do
            expect { action.call env }.to raise_error Errors::InvalidNodeError
          end
        end
      end

		end

	end

end
