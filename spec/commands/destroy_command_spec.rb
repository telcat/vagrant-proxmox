require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider destroy command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions to print a ui message that the vm is not created' do
				Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::MessageNotCreated.should be_called
				Action::DestroyVm.should be_ommited
				execute_vagrant_command environment, :destroy
			end
		end

		context 'the vm exists on the proxmox server' do

			context 'the destroy command is not confirmed' do
				it 'should call the appropriate actions to print a ui message that the vm will not be destroyed' do
					Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
					Action::IsCreated.should be_called { |env| env[:result] = true }
					::Vagrant::Action::Builtin::DestroyConfirm.should be_called { |env| env[:result] = false }
					::VagrantPlugins::ProviderVirtualBox::Action::MessageWillNotDestroy.should be_called
					Action::DestroyVm.should be_ommited
					execute_vagrant_command environment, :destroy
				end
			end

			context 'the destroy command is confirmed' do
				context 'the vm is running' do
					it 'should call the appropriate actions to destroy the vm' do
						Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
						Action::IsCreated.should be_called { |env| env[:result] = true }
						::Vagrant::Action::Builtin::DestroyConfirm.should be_called { |env| env[:result] = true }
						Action::IsStopped.should be_called { |env| env[:result] = false }
						Action::ShutdownVm.should be_called
						Action::DestroyVm.should be_called
						::Vagrant::Action::Builtin::ProvisionerCleanup.should be_called
						Action::CleanupAfterDestroy.should be_called
						execute_vagrant_command environment, :destroy
					end
				end

				context 'the vm is stopped' do
					it 'should call the appropriate actions to destroy the vm' do
						Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
						Action::IsCreated.should be_called { |env| env[:result] = true }
						Action::DestroyConfirm.should be_called { |env| env[:result] = true }
						Action::IsStopped.should be_called { |env| env[:result] = true }
						Action::DestroyVm.should be_called
						::Vagrant::Action::Builtin::ProvisionerCleanup.should be_called
						Action::CleanupAfterDestroy.should be_called
						Action::ShutdownVm.should be_ommited
						execute_vagrant_command environment, :destroy
					end
				end
			end

		end

	end

end
