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

		describe '#template_file' do
			subject { super().template_file }
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

		describe '#ssh_timeout' do
			subject { super().ssh_timeout }
			it { is_expected.to eq(60) }
		end

		describe '#ssh_status_check_interval' do
			subject { super().ssh_status_check_interval }
			it { is_expected.to eq(5) }
		end

	end

	describe 'of a given Vagrantfile' do

		let(:proxmox_os_template) { "proxmox.os_template = 'local:vztmpl/template.tar.gz'" }
		let(:proxmox_template_file) { '' }
		let(:vagrantfile_content) { "
Vagrant.configure('2') do |config|
	config.vm.provider :proxmox do |proxmox|
		proxmox.endpoint = 'https://proxmox.example.com/api2/json'
		proxmox.user_name = 'vagrant'
		proxmox.password = 'password'
    #{proxmox_os_template}
		#{proxmox_template_file}
		proxmox.vm_id_range = 900..910
		proxmox.vm_name_prefix = 'vagrant_test_'
		proxmox.vm_memory = 256
		proxmox.task_timeout = 30
		proxmox.task_status_check_interval = 1
	end

	config.vm.define :machine, primary: true do |machine|
		machine.vm.box = 'b681e2bc-617b-4b35-94fa-edc92e1071b8'
	end
end
" }

		let(:vagrantfile) do
			File.open("#{Dir.tmpdir}/#{Dir::Tmpname.make_tmpname 'rspec', nil }", 'w').tap do |file|
				file.write vagrantfile_content
				file.flush
			end
		end

		let(:environment) { Vagrant::Environment.new vagrantfile_name: vagrantfile.path }
		let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

		after { File.unlink (vagrantfile.path) }

		describe 'overwriting defaults' do

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

			context 'with an existing template file' do
				describe '#os_template' do
					before do
					end
					subject { super().os_template }
					it { is_expected.to eq('local:vztmpl/template.tar.gz') }
				end
			end

			context 'with a new template file' do
				let(:proxmox_os_template) { "" }
				let(:proxmox_template_file) { "proxmox.template_file = 'template.tar.gz'" }

				describe '#template_file' do
					before do
					end
					subject { super().template_file }
					it { is_expected.to eq('template.tar.gz') }
				end
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

		describe 'is validated' do
			let(:machine) { double 'machine' }
			let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
			let(:config) { environment.machine(environment.primary_machine_name, :proxmox).config.vm.get_provider_config :proxmox }

			subject { config }

			context 'when the vagrantfile is valid' do
				specify 'the configuration should be valid' do
					expect(subject.validate(machine)).to eq({'Proxmox Provider' => []})
				end
			end

			context 'when the vagrantfile is erroneous' do

				describe 'because of a missing endpoint' do
					before { subject.endpoint = nil }
					specify 'it should report an error' do
						expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No endpoint specified.']})
					end
				end

				describe 'because of a missing user_name' do
					before { subject.user_name = nil }
					specify 'it should report an error' do
						expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No user_name specified.']})
					end
				end

				describe 'because of a missing password' do
					before { subject.password = nil }
					specify 'it should report an error' do
						expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No password specified.']})
					end
				end

				describe 'because of a missing os_template and missing template_file' do
					before do
						subject.os_template = nil
						subject.template_file = nil
					end
					specify 'it should report an error' do
						expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No os_template or template_file specified.']})
					end
				end
			end
		end

		describe 'is finalized' do

			context 'a template file was specified' do

				let(:proxmox_os_template) { '' }
				let(:proxmox_template_file) { "proxmox.template_file = '/my/dir/mytemplate.tar.gz'" }

				it 'should set the os_template to the uploaded template file' do
					expect(config.os_template).to eq('local:vztmpl/mytemplate.tar.gz')
				end
			end
		end
	end
end