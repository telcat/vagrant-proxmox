require 'spec_helper'
require 'vagrant-proxmox/config'

describe VagrantPlugins::Proxmox::Config do

	describe 'defaults' do
		subject { super().tap { |o| o.finalize! } }

		describe '#endpoint' do
		  subject { super().endpoint }
		  it { is_expected.to be_nil }
		end

		describe '#user_name' do
		  subject { super().user_name }
		  it { is_expected.to be_nil }
		end

		describe '#password' do
		  subject { super().password }
		  it { is_expected.to be_nil }
		end

		describe '#os_template' do
		  subject { super().os_template }
		  it { is_expected.to be_nil }
		end

		describe '#vm_id_range' do
		  subject { super().vm_id_range }
		  it { is_expected.to eq(900..999) }
		end

		describe '#vm_name_prefix' do
		  subject { super().vm_name_prefix }
		  it { is_expected.to eq('vagrant_') }
		end

		describe '#vm_memory' do
		  subject { super().vm_memory }
		  it { is_expected.to eq(512) }
		end

		describe '#task_timeout' do
		  subject { super().task_timeout }
		  it { is_expected.to eq(60) }
		end

		describe '#task_status_check_interval' do
		  subject { super().task_status_check_interval }
		  it { is_expected.to eq(2) }
		end
	end

	describe 'overwriting defaults using a Vagrantfile' do
		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

		subject { config }

		describe '#endpoint' do
		  subject { super().endpoint }
		  it { is_expected.to eq('https://proxmox.example.com/api2/json') }
		end

		describe '#user_name' do
		  subject { super().user_name }
		  it { is_expected.to eq('vagrant') }
		end

		describe '#password' do
		  subject { super().password }
		  it { is_expected.to eq('password') }
		end

		describe '#os_template' do
		  subject { super().os_template }
		  it { is_expected.to eq('local:vztmpl/template.tgz') }
		end

		describe '#vm_id_range' do
		  subject { super().vm_id_range }
		  it { is_expected.to eq(900..910) }
		end

		describe '#vm_name_prefix' do
		  subject { super().vm_name_prefix }
		  it { is_expected.to eq('vagrant_test_') }
		end

		describe '#vm_memory' do
		  subject { super().vm_memory }
		  it { is_expected.to eq(256) }
		end

		describe '#task_timeout' do
		  subject { super().task_timeout }
		  it { is_expected.to eq(30) }
		end

		describe '#task_status_check_interval' do
		  subject { super().task_status_check_interval }
		  it { is_expected.to eq(1) }
		end
	end

	describe 'Configuration validation' do
		let(:machine) { double 'machine' }
		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

		subject { config }

		describe 'with a valid configuration' do
			it 'should validate without any error' do
				expect(subject.validate(machine)).to eq({'Proxmox Provider' => []})
			end
		end

		describe 'with a missing endpoint' do
			before { subject.endpoint = nil }
			specify { expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No endpoint specified.']}) }
		end

		describe 'with a missing user_name' do
			before { subject.user_name = nil }
			specify { expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No user_name specified.']}) }
		end

		describe 'with a missing password' do
			before { subject.password = nil }
			specify { expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No password specified.']}) }
		end

		describe 'with a missing os_template' do
			before { subject.os_template = nil }
			specify { expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No os_template specified.']}) }
		end
	end

end
