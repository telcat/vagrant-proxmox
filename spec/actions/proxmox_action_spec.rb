require 'spec_helper'

module VagrantPlugins::Proxmox

	describe Action::ProxmoxAction do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_connection: connection} }

		let (:action) { subject }

		describe '#next_action' do

			let(:app) { double('app') }
			before { action.instance_variable_set(:@app, app) }

			it 'should call @app' do
				app.should_receive(:call)
				action.send(:next_action, env)
			end
		end

		describe '#get_machine_ip_address' do

			before do
				env[:machine].config.vm.stub networks: [[:private_network, {ip: '4.3.2.1'}], [:public_network, {ip: '1.2.3.4'}]]
			end

			it 'should return the first public ip address from the configuration' do
				action.send(:get_machine_ip_address, env).should == '1.2.3.4'
			end

			context 'no network configuration exists' do

				before do
					env[:machine].config.vm.stub networks: nil
				end

				it 'should return nil' do
					action.send(:get_machine_ip_address, env).should be_nil
				end

			end

		end

		describe '#connection' do
			it 'should retrieve the connection from the environment' do
				action.send(:connection, env).should == connection
			end
		end

	end

end