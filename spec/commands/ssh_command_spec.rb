require 'spec_helper'

module VagrantPlugins::Proxmox

	describe 'Vagrant Proxmox provider ssh command', :need_box do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:ui) { double('ui').as_null_object }

		context 'the vm is not created on the proxmox server' do
			it 'should call the appropriate actions and print a ui message that the vm is not created' do
				Action::IsCreated.should be_called { |env| env[:result] = false }
				Action::MessageNotCreated.should be_called
				Action::SSHExec.should be_omitted
				execute_vagrant_command environment, :ssh
			end
		end

		context 'the vm exists on the proxmox server' do

			it 'should call the appropriate actions to open a ssh connection' do
				Action::IsCreated.should be_called { |env| env[:result] = true }
				Action::SSHExec.should be_called
				execute_vagrant_command environment, :ssh
			end

		end

	end

end
