require 'spec_helper'
require 'vagrant-proxmox/config'

describe VagrantPlugins::Proxmox::Config do

	describe 'defaults' do
		subject { super().tap { |o| o.finalize! } }

		its(:endpoint) { should be_nil }
		its(:user_name) { should be_nil }
		its(:password) { should be_nil }
		its(:os_template) { should be_nil }
		its(:vm_id_range) { should == (900..999) }
		its(:vm_name_prefix) { should == 'vagrant_' }
		its(:vm_memory) { should == 512 }
		its(:task_timeout) { should == 60 }
		its(:task_status_check_interval) { should == 2 }
	end

	describe 'overwriting defaults using a Vagrantfile' do
		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

		subject { config }

		its(:endpoint) { should == 'https://your.proxmox.server/api2/json' }
		its(:user_name) { should == 'vagrant' }
		its(:password) { should == 'password' }
		its(:os_template) { should == 'local:vztmpl/template.tgz' }
		its(:vm_id_range) { should == (900..910) }
		its(:vm_name_prefix) { should == 'vagrant_test_' }
		its(:vm_memory) { should == 256 }
		its(:task_timeout) { should == 30 }
		its(:task_status_check_interval) { should == 1 }
	end

	describe 'Configuration validation' do
		let(:machine) { double 'machine' }
		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

		subject { config }

		describe 'with a valid configuration' do
			it 'should validate without any error' do
				subject.validate(machine).should == {'Proxmox Provider' => []}
			end
		end

		describe 'with a missing endpoint' do
			before { subject.endpoint = nil }
			specify { subject.validate(machine).should == {'Proxmox Provider' => ['No endpoint specified.']} }
		end

		describe 'with a missing user_name' do
			before { subject.user_name = nil }
			specify { subject.validate(machine).should == {'Proxmox Provider' => ['No user_name specified.']} }
		end

		describe 'with a missing password' do
			before { subject.password = nil }
			specify { subject.validate(machine).should == {'Proxmox Provider' => ['No password specified.']} }
		end

		describe 'with a missing os_template' do
			before { subject.os_template = nil }
			specify { subject.validate(machine).should == {'Proxmox Provider' => ['No os_template specified.']} }
		end
	end

end
