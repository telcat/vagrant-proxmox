require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider provision command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				expect(Action::ConfigValidate).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = false }
				expect(Action::MessageNotCreated).to be_called
				expect(Action::Provision).to be_omitted
				expect(Action::SyncFolders).to be_omitted
				execute_vagrant_command environment, :provision
			end
		end

		context 'the vm exists on the proxmox server' do
			it 'should call the appropriate actions and provision the vm' do
				expect(Action::ConfigValidate).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = false }
				expect(Action::Provision).to be_called
				expect(Action::SyncFolders).to be_called
				execute_vagrant_command environment, :provision
			end
		end

		context 'the vm exists on the proxmox server but is not running' do

			it 'should state that the machine is not currently running' do
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = true }
				expect(Action::MessageNotRunning).to be_called
				expect(Action::Provision).to be_omitted
				execute_vagrant_command environment, :provision
			end

		end

	end

end
