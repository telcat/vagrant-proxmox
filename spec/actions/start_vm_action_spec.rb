require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::StartVm do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://proxmox.example.com/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 ui: double('ui').as_null_object,
								 proxmox_connection: connection} }
		let(:ssh_reachable) { true }
		let(:ssh_timeout) { 60 }
		let(:ssh_status_check_interval) { 5 }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

			before do
				env[:machine].id = 'localhost/100'
				allow(connection).to receive_messages :start_vm => 'OK'
				allow(env[:machine].communicate).to receive_messages :ready? => ssh_reachable
			end

			it_behaves_like 'a proxmox action call'

			it 'should call the start_vm function of connection' do
				expect(connection).to receive(:start_vm).with node: 'localhost', vm_id: '100'
				action.call env
			end

			it 'should print a message to the user interface' do
				expect(env[:ui]).to receive(:info).with 'Starting the virtual machine...'
				expect(env[:ui]).to receive(:info).with 'Done!'
				expect(env[:ui]).to receive(:info).with 'Waiting for SSH connection...'
				expect(env[:ui]).to receive(:info).with 'Done!'
				action.call env
			end

			it 'should periodically call env[:machine].communicate.ready? to check for ssh access' do
				expect(env[:machine].communicate).to receive(:ready?).and_return false
				expect(subject).to receive(:sleep).with ssh_status_check_interval
				expect(env[:machine].communicate).to receive(:ready?).and_return true
				action.call env
			end

			context 'when the proxmox server responds with an error to the start request' do

				context 'when the proxmox server replies with an internal server error to the start request' do
					it 'should raise a VMStartError' do
						allow(connection).to receive(:start_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMStartError
					end
				end

				context 'when the proxmox server replies with an internal server error to the task status request' do
					it 'should raise a VMStartError' do
						allow(connection).to receive(:start_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMStartError
					end
				end

				context 'when the proxmox server does not reply the task status request with OK' do
					it 'should raise a VMStartError' do
						allow(connection).to receive_messages :start_vm => 'start vm error'
						expect { action.send :call, env }.to raise_error Errors::VMStartError, /start vm error/
					end
				end

			end

			context 'when no ssh connection can be established after startup' do

				let(:ssh_reachable) { false }

				before do
					allow(action).to receive(:sleep) { |duration| Timecop.travel(Time.now + duration) }
					Timecop.freeze
				end

				after do
					Timecop.return
				end

				it 'should wait the default timeout' do
					begin
						action.call env
					rescue Errors::SSHError
					end
					expect(Time).to have_elapsed ssh_timeout.seconds
				end

				it 'should raise an ssh error' do
					expect { action.send :call, env }.to raise_error Errors::SSHError, /Unable to establish an ssh connection/
				end
			end
		end
	end
end
