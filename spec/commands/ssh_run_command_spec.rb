require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider ssh exec command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox), ui: double('ui').as_null_object} }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				expect(Action::IsCreated).to be_called { |env| env[:result] = false }
				expect(Action::MessageNotCreated).to be_called
				expect(Action::SSHRun).to be_omitted
				execute_vagrant_command environment, :ssh, '--command', 'foo'
			end
		end

		context 'the vm exists on the proxmox server' do
			before { allow(env[:machine]).to receive(:ssh_info) { {host: '127.0.0.1', port: 22, username: 'vagrant', private_key_path: 'key'} } }

			it 'should call the appropriate actions to execute a command via ssh on the vm' do
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = false }
				expect(Action::SSHRun).to be_called
				execute_vagrant_command environment, :ssh, '--command', 'foo'
			end
		end

		context 'the vm exists on the proxmox server and is not running' do
			before { allow(env[:machine]).to receive(:ssh_info) { {host: '127.0.0.1', port: 22, username: 'vagrant', private_key_path: 'key'} } }

			it 'should call the appropriate actions to execute a command via ssh on the vm' do
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = true }
				expect(Action::MessageNotRunning).to be_called
				expect(Action::SSHRun).to be_omitted
				execute_vagrant_command environment, :ssh, '--command', 'foo'
			end
		end

	end

end
