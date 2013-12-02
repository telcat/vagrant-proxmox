require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider up command' do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		before do
			Vagrant::UI::Interface.stub(:new).and_return ui
		end

		context 'the vm is not yet created' do
			it 'should call the appropriate actions and print a ui message that the vm will be created' do
				Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
				Action::GetNodeList.should be_called { |env| env[:proxmox_nodes] = [{node: 'localhost'}] }
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::CreateVm.should be_called { |env| env[:machine].id = 'localhost/100' }
				Action::Provision.should be_called
				Action::StartVm.should be_called
				Action::SyncFolders.should be_called
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

		context 'the vm is stopped' do
			it 'should call the appropriate actions and print a ui message that the vm will be started' do
				Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::IsStopped.should be_called { |env| env[:result] = true }
				Action::Provision.should be_called
				Action::StartVm.should be_called
				Action::SyncFolders.should be_called
				Action::CreateVm.should be_ommited
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

		context 'the vm is already running' do
			it 'should call the appropriate actions and print a ui message that the vm is already running' do
				Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::IsStopped.should be_called { |env| env[:result] = false }
				Action::MessageAlreadyRunning.should be_called
				Action::Provision.should be_ommited
				Action::CreateVm.should be_ommited
				Action::StartVm.should be_ommited
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

	end

end
