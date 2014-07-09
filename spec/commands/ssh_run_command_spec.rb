require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider ssh exec command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox), ui: double('ui').as_null_object} }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::MessageNotCreated.should be_called
				Action::SSHRun.should be_omitted
				execute_vagrant_command environment, :ssh, '--command', 'foo'
			end
		end

		context 'the vm exists on the proxmox server' do
			before { env[:machine].stub(:ssh_info) { {host: '127.0.0.1', port: 22, username: 'vagrant', private_key_path: 'key'} } }

			it 'should call the appropriate actions to execute a command via ssh on the vm' do
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::SSHRun.should be_called
				execute_vagrant_command environment, :ssh, '--command', 'foo'
			end
		end

	end

end
