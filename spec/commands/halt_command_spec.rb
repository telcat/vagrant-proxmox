require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider halt command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				Action::ConfigValidate.should be_called
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::MessageNotCreated.should be_called
				Action::ConnectProxmox.should be_omitted
				Action::ShutdownVm.should be_omitted
				execute_vagrant_command environment, :halt
			end
		end

		context 'the vm is stopped' do
			it 'should not shut down the vm and print a vm message that the vm is already stopped' do
				Action::ConfigValidate.should be_called
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::IsStopped.should be_called { |env| env[:result] = true }
				Action::MessageAlreadyStopped.should be_called
				Action::ConnectProxmox.should be_omitted
				Action::ShutdownVm.should be_omitted
				execute_vagrant_command environment, :halt
			end
		end

		context 'the vm is running' do
			it 'should call the appropriate actions to shut down the vm' do
				Action::ConfigValidate.should be_called
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::IsStopped.should be_called { |env| env[:result] = false }
				Action::ConnectProxmox.should be_called
				Action::ShutdownVm.should be_called
				execute_vagrant_command environment, :halt
			end
		end

	end

end
