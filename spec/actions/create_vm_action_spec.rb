require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::CreateVm do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_nodes: ['localhost'],
								 ui: double('ui').as_null_object,
								 proxmox_connection: connection} }
		let(:app) { double('app').as_null_object }
		let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:vzcreate:100:vagrant@pve:' }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before do
			connection.stub :get_free_vm_id => 100
			connection.stub :create_vm => 'OK'
		end

		describe '#call' do

			it_behaves_like 'a proxmox action call'

			describe 'the call to create a new virtual machine' do

				context 'with default config' do
					specify do
						connection.should_receive(:create_vm).
							with(node: 'localhost',
									 params: {vmid: 100,
										hostname: 'box',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'})
						action.call env
					end
				end

				context 'with a specified hostname' do
					before { env[:machine].config.vm.hostname = 'hostname' }
					specify do
						connection.should_receive(:create_vm).
							with(node: 'localhost',
									 params: {vmid: 100,
										hostname: 'hostname',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'})
						action.call env
					end
				end

				context 'with a specified ip address' do
					before { env[:machine].config.vm.stub(:networks) { [[:public_network, {ip: '127.0.0.1'}]] } }
					specify do
						connection.should_receive(:create_vm).
							with(node: 'localhost',
									 params: {vmid: 100,
										hostname: 'box',
										ip_address: '127.0.0.1',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'})
						action.call env
					end
				end

			end

			it 'should print a message to the user interface' do
				env[:ui].should_receive(:info).with 'Creating the virtual machine...'
				env[:ui].should_receive(:info).with 'Done!'
				action.call env
			end

			it 'should store the node and vmid in env[:machine].id' do
				action.call env
				env[:machine].id.should == 'localhost/100'
			end

			it 'should get a free vm id from connection' do
				connection.should_receive(:get_free_vm_id)
				action.send :call, env
			end

			context 'when the proxmox server responds with an error to the create request' do

				context 'when the proxmox server replies with an internal server error to the delete_vm call' do
					it 'should raise a VMCreateError' do
						connection.stub(:create_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMCreateError
					end
				end

				context 'when the proxmox server replies with an internal server error to the task status request' do
					it 'should raise a VMCreateError' do
						connection.stub(:create_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMCreateError
					end
				end

				context 'when the proxmox server does not reply the task status request with OK' do
					it 'should raise a VMCreateError' do
						connection.stub :create_vm => 'create vm error'
						expect { action.send :call, env }.to raise_error Errors::VMCreateError, /create vm error/
					end
				end

			end

		end

	end

end
