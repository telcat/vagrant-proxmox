require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider provision command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				Action::ConfigValidate.should be_called
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::MessageNotCreated.should be_called
				Action::Provision.should be_ommited
				Action::SyncFolders.should be_ommited
				execute_vagrant_command environment, :provision
			end
		end

		context 'the vm exists on the proxmox server' do
			it 'should call the appropriate actions and provision the vm' do
				Action::ConfigValidate.should be_called
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::Provision.should be_called
				Action::SyncFolders.should be_called
				execute_vagrant_command environment, :provision
			end
		end

	end

end
