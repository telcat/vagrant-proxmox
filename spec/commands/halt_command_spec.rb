require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider halt command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				expect(Action::ConfigValidate).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = false }
				expect(Action::MessageNotCreated).to be_called
				expect(Action::ConnectProxmox).to be_omitted
				expect(Action::ShutdownVm).to be_omitted
				execute_vagrant_command environment, :halt
			end
		end

		context 'the vm is stopped' do
			it 'should not shut down the vm and print a vm message that the vm is already stopped' do
				expect(Action::ConfigValidate).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = true }
				expect(Action::MessageAlreadyStopped).to be_called
				expect(Action::ConnectProxmox).to be_omitted
				expect(Action::ShutdownVm).to be_omitted
				execute_vagrant_command environment, :halt
			end
		end

		context 'the vm is running' do
			it 'should call the appropriate actions to shut down the vm' do
				expect(Action::ConfigValidate).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = false }
				expect(Action::ConnectProxmox).to be_called
				expect(Action::ShutdownVm).to be_called
				execute_vagrant_command environment, :halt
			end
		end

	end

end
