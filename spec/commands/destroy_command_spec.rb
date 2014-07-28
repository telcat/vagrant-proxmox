require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider destroy command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions to print a ui message that the vm is not created' do
				expect(Action::ConnectProxmox).to be_called
				expect(Action::IsCreated).to be_called { |env| env[:result] = false }
				expect(Action::MessageNotCreated).to be_called
				expect(Action::DestroyVm).to be_omitted
				execute_vagrant_command environment, :destroy
			end
		end

		context 'the vm exists on the proxmox server' do

			context 'the destroy command is not confirmed' do
				it 'should call the appropriate actions to print a ui message that the vm will not be destroyed' do
					expect(Action::ConnectProxmox).to be_called
					expect(Action::IsCreated).to be_called { |env| env[:result] = true }
					expect(::Vagrant::Action::Builtin::DestroyConfirm).to be_called { |env| env[:result] = false }
					expect(::VagrantPlugins::ProviderVirtualBox::Action::MessageWillNotDestroy).to be_called
					expect(Action::DestroyVm).to be_omitted
					execute_vagrant_command environment, :destroy
				end
			end

			context 'the destroy command is confirmed' do
				context 'the vm is running' do
					it 'should call the appropriate actions to destroy the vm' do
						expect(Action::ConnectProxmox).to be_called
						expect(Action::IsCreated).to be_called { |env| env[:result] = true }
						expect(::Vagrant::Action::Builtin::DestroyConfirm).to be_called { |env| env[:result] = true }
						expect(Action::IsStopped).to be_called { |env| env[:result] = false }
						expect(Action::ShutdownVm).to be_called
						expect(Action::DestroyVm).to be_called
						expect(::Vagrant::Action::Builtin::ProvisionerCleanup).to be_called
						expect(Action::CleanupAfterDestroy).to be_called
						execute_vagrant_command environment, :destroy
					end
				end

				context 'the vm is stopped' do
					it 'should call the appropriate actions to destroy the vm' do
						expect(Action::ConnectProxmox).to be_called
						expect(Action::IsCreated).to be_called { |env| env[:result] = true }
						expect(Action::DestroyConfirm).to be_called { |env| env[:result] = true }
						expect(Action::IsStopped).to be_called { |env| env[:result] = true }
						expect(Action::DestroyVm).to be_called
						expect(::Vagrant::Action::Builtin::ProvisionerCleanup).to be_called
						expect(Action::CleanupAfterDestroy).to be_called
						expect(Action::ShutdownVm).to be_omitted
						execute_vagrant_command environment, :destroy
					end
				end
			end

		end

	end

end
