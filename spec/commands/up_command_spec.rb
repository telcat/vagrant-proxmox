require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider up command' do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		before do
			allow(Vagrant::UI::Interface).to receive_messages :new => ui
		end

		context 'the vm is not yet created' do
			it 'should call the appropriate actions and print a ui message that the vm will be created' do
				expect(Action::ConnectProxmox).to be_called
				expect(Action::GetNodeList).to be_called { |env| env[:proxmox_nodes] = ['localhost'] }
				expect(Action::IsCreated).to be_called { |env| env[:result] = false }
				expect(Action::CreateVm).to be_called { |env| env[:machine].id = 'localhost/100' }
				expect(Action::Provision).to be_called
				expect(Action::StartVm).to be_called
				expect(Action::SyncFolders).to be_called
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

		context 'the vm is stopped' do
			it 'should call the appropriate actions and print a ui message that the vm will be started' do
				expect(Action::ConnectProxmox).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = true }
				expect(Action::Provision).to be_called
				expect(Action::StartVm).to be_called
				expect(Action::SyncFolders).to be_called
				expect(Action::CreateVm).to be_omitted
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

		context 'the vm is already running' do
			it 'should call the appropriate actions and print a ui message that the vm is already running' do
				expect(Action::ConnectProxmox).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = true }
				expect(Action::IsStopped).to be_called { |env| env[:result] = false }
				expect(Action::MessageAlreadyRunning).to be_called
				expect(Action::Provision).to be_omitted
				expect(Action::CreateVm).to be_omitted
				expect(Action::StartVm).to be_omitted
				execute_vagrant_command environment, :up, '--provider=proxmox'
			end
		end

	end

end
