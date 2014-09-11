require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::CreateVm do

		let(:vagrantfile) { 'dummy_box/Vagrantfile' }
		let(:environment) { Vagrant::Environment.new vagrantfile_name: vagrantfile }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_selected_node: 'localhost',
								 ui: double('ui').as_null_object,
								 proxmox_connection: connection} }
		let(:app) { double('app').as_null_object }
		let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:vzcreate:100:vagrant@pve:' }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before do
			allow(connection).to receive_messages :get_free_vm_id => 100
			allow(connection).to receive_messages :create_vm => 'OK'
		end

		describe '#call' do

			it_behaves_like 'a proxmox action call'

			describe 'the call to create a new virtual machine' do

				context 'when the vm_type is :openvz' do

					let(:vagrantfile) { 'dummy_box/Vagrantfile' }
					before { allow(env[:machine].provider_config).to receive(:vm_type) { :openvz } }

					context 'with default config' do
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :openvz,
																					 params: {vmid: 100,
																										hostname: 'machine',
																										ostemplate: 'local:vztmpl/template.tar.gz',
																										password: 'vagrant',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end

					context 'with a specified hostname' do
						before { env[:machine].config.vm.hostname = 'hostname' }
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :openvz,
																					 params: {vmid: 100,
																										hostname: 'hostname',
																										ostemplate: 'local:vztmpl/template.tar.gz',
																										password: 'vagrant',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end

					context 'with a specified ip address' do
						before { allow(env[:machine].config.vm).to receive(:networks) { [[:public_network, {ip: '127.0.0.1'}]] } }
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :openvz,
																					 params: {vmid: 100,
																										hostname: 'machine',
																										ip_address: '127.0.0.1',
																										ostemplate: 'local:vztmpl/template.tar.gz',
																										password: 'vagrant',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end
				end

				context 'when the vm_type is :qemu' do

					let(:vagrantfile) { 'dummy_box/Vagrantfile_qemu' }
					before { allow(env[:machine].provider_config).to receive(:vm_type) { :qemu } }

					context 'with default config' do
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :qemu,
																					 params: {vmid: 100,
																										name: 'machine',
																										ostype: :l26,
																										ide2: 'local:iso/isofile.iso,media=cdrom',
																										sata0: 'raid:30,format=qcow2',
																										sockets: 1,
																										cores: 1,
																										net0: 'e1000,bridge=vmbr0',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end

					context 'with a specified hostname' do
						before { env[:machine].config.vm.hostname = 'hostname' }
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :qemu,
																					 params: {vmid: 100,
																										name: 'hostname',
																										ostype: :l26,
																										ide2: 'local:iso/isofile.iso,media=cdrom',
																										sata0: 'raid:30,format=qcow2',
																										sockets: 1,
																										cores: 1,
																										net0: 'e1000,bridge=vmbr0',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end

					context 'with predefined network settings' do
						before { allow(env[:machine].config.vm).to receive(:networks) { [[:public_network, {ip: '127.0.0.1', macaddress: 'aa:bb:cc:dd:ee:ff'}]] } }
						specify do
							expect(connection).to receive(:create_vm).
																			with(node: 'localhost',
																					 vm_type: :qemu,
																					 params: {vmid: 100,
																										name: 'machine',
																										ostype: :l26,
																										ide2: 'local:iso/isofile.iso,media=cdrom',
																										sata0: 'raid:30,format=qcow2',
																										sockets: 1,
																										cores: 1,
																										net0: 'e1000=aa:bb:cc:dd:ee:ff,bridge=vmbr0',
																										memory: 256,
																										description: 'vagrant_test_machine'})
							action.call env
						end
					end
				end
			end

			it 'should print a message to the user interface' do
				expect(env[:ui]).to receive(:info).with 'Creating the virtual machine...'
				expect(env[:ui]).to receive(:info).with 'Done!'
				action.call env
			end

			it 'should store the node and vmid in env[:machine].id' do
				action.call env
				expect(env[:machine].id).to eq('localhost/100')
			end

			it 'should get a free vm id from connection' do
				expect(connection).to receive(:get_free_vm_id)
				action.send :call, env
			end

			context 'when the proxmox server responds with an error to the create request' do

				context 'when the proxmox server replies with an internal server error to the delete_vm call' do
					it 'should raise a VMCreateError' do
						allow(connection).to receive(:create_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMCreateError
					end
				end

				context 'when the proxmox server replies with an internal server error to the task status request' do
					it 'should raise a VMCreateError' do
						allow(connection).to receive(:create_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMCreateError
					end
				end

				context 'when the proxmox server does not reply the task status request with OK' do
					it 'should raise a VMCreateError' do
						allow(connection).to receive_messages :create_vm => 'create vm error'
						expect { action.send :call, env }.to raise_error Errors::VMCreateError, /create vm error/
					end
				end
			end
		end
	end
end
