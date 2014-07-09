require 'spec_helper'
require 'vagrant-proxmox/provider'

module VagrantPlugins::Proxmox

	describe Provider do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:machine) { environment.machine(environment.primary_machine_name, :proxmox) }
		let(:ui) { double('ui').as_null_object }

		subject { described_class.new(machine) }

		describe '#ssh_info', :need_box do
			it 'should call the appropriate actions and return the ssh info' do
				Action::ConfigValidate.should be_called
				Action::ConnectProxmox.should be_called
				Action::ReadSSHInfo.should be_called { |env| env[:machine_ssh_info] = 'ssh_info'}
				subject.ssh_info.should == 'ssh_info'
			end
		end

	end

end
