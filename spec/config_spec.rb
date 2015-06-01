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

		describe '#vm_type' do
			subject { super().vm_type }
			it { is_expected.to be_nil }
		end

		describe '#openvz_os_template' do
			subject { super().openvz_os_template }
			it { is_expected.to be_nil }
		end

		describe '#openvz_template_file' do
			subject { super().openvz_template_file }
			it { is_expected.to be_nil }
		end

		describe '#replace_openvz_template_file' do
			subject { super().replace_openvz_template_file }
			it { is_expected.to eq(false) }
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

		describe '#imgcopy_timeout' do
			subject { super().imgcopy_timeout }
			it { is_expected.to eq(120) }
		end

		describe '#qemu_os' do
			subject { super().qemu_os }
			it { is_expected.to be_nil }
		end

		describe '#qemu_iso' do
			subject { super().qemu_iso }
			it { is_expected.to be_nil }
		end

		describe '#qemu_iso_file' do
			subject { super().qemu_iso_file }
			it { is_expected.to be_nil }
		end

		describe '#replace_qemu_iso_file' do
			subject { super().replace_qemu_iso_file }
			it { is_expected.to eq(false) }
		end

		describe '#qemu_disk_size' do
			subject { super().qemu_disk_size }
			it { is_expected.to be_nil }
		end

	end

	describe 'of a given Vagrantfile' do

		let(:proxmox_qemu_iso) { '' }
		let(:proxmox_openvz_os_template) { "proxmox.openvz_os_template = 'local:vztmpl/template.tar.gz'" }
		let(:proxmox_openvz_template_file) { '' }
		let(:proxmox_replace_openvz_template_file) { '' }
		let(:proxmox_vm_type) { 'proxmox.vm_type = :openvz' }
		let(:proxmox_qemu_iso_file) { '' }
		let(:proxmox_replace_qemu_iso_file) { '' }
		let(:proxmox_qemu_disk_size) { '' }
		let(:vagrantfile_content) { "
Vagrant.configure('2') do |config|
	config.vm.provider :proxmox do |proxmox|
		proxmox.endpoint = 'https://proxmox.example.com/api2/json'
		proxmox.user_name = 'vagrant'
		proxmox.password = 'password'
    #{proxmox_vm_type}
		#{proxmox_openvz_os_template}
		#{proxmox_openvz_template_file}
		#{proxmox_replace_openvz_template_file}
		#{proxmox_qemu_iso}
		#{proxmox_qemu_iso_file}
		#{proxmox_replace_qemu_iso_file}
		#{proxmox_qemu_disk_size}
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
				describe '#openvz_os_template' do
					before do
					end
					subject { super().openvz_os_template }
					it { is_expected.to eq('local:vztmpl/template.tar.gz') }
				end
			end

			context 'with a new template file' do
				let(:proxmox_openvz_os_template) { "" }
				let(:proxmox_openvz_template_file) { "proxmox.openvz_template_file = 'template.tar.gz'" }

				describe '#openvz_template_file' do
					before do
					end
					subject { super().openvz_template_file }
					it { is_expected.to eq('template.tar.gz') }
				end
			end

			context 'with a new template file to be overwritten' do
				let(:proxmox_replace_openvz_template_file) { 'proxmox.replace_openvz_template_file = true' }

				describe '#openvz_template_file' do
					before do
					end
					subject { super().replace_openvz_template_file }
					it { is_expected.to eq(true) }
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

				describe 'because of a missing vm_type' do
					before { subject.vm_type = nil }
					specify 'it should report an error' do
						expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No vm_type specified']})
					end
				end

				context 'with vm_type = :openvz' do

					describe 'because of a missing openvz_os_template and missing openvz_template_file' do
						before do
							subject.openvz_os_template = nil
							subject.openvz_template_file = nil
						end
						specify 'it should report an error' do
							expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No openvz_os_template or openvz_template_file specified for vm_type=:openvz']})
						end
					end
				end

				context 'with vm_type = :qemu' do

					before do
						subject.vm_type = :qemu
						subject.qemu_os = :l26
						subject.qemu_iso = 'anyiso.iso'
						subject.qemu_disk_size = '30G'
					end

					describe 'because of a missing qemu_iso and missing qemu_iso_file' do
						before do
							subject.qemu_iso = nil
							subject.qemu_iso_file = nil
						end
						specify 'it should report an error' do
							expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No qemu_iso or qemu_iso_file specified for vm_type=:qemu']})
						end
					end

					describe 'because of a missing qemu_os_type' do
						before do
							subject.qemu_os = nil
						end
						specify 'it should report an error' do
							expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No qemu_os specified for vm_type=:qemu']})
						end
					end

					describe 'because of a missing qemu_disk_size' do
						before do
							subject.qemu_disk_size = nil
						end
						specify 'it should report an error' do
							expect(subject.validate(machine)).to eq({'Proxmox Provider' => ['No qemu_disk_size specified for vm_type=:qemu']})
						end
					end

				end
			end
		end

		describe 'is finalized' do

			context 'with vm_type=:openvz' do

				context 'a template file was specified' do

					let(:proxmox_openvz_os_template) { '' }
					let(:proxmox_openvz_template_file) { "proxmox.openvz_template_file = '/my/dir/mytemplate.tar.gz'" }

					it 'should set the openvz_os_template to the uploaded template file' do
						expect(config.openvz_os_template).to eq('local:vztmpl/mytemplate.tar.gz')
					end
				end

			end

			context 'with vm_type=:qemu' do

				context 'an iso file was specified' do

					let(:proxmox_openvz_os_template) { '' }
					let(:proxmox_openvz_template_file) { '' }
					let(:proxmox_qemu_iso) { '' }
					let(:proxmox_qemu_iso_file) { "proxmox.qemu_iso_file = '/my/dir/myiso.iso'" }

					it 'should set the openvz_os_template to the uploaded template file' do
						expect(config.qemu_iso).to eq('local:iso/myiso.iso')
					end
				end

				context 'when the disk size contains a unit' do

					let (:proxmox_qemu_disk_size) { "proxmox.qemu_disk_size = '15G' " }

					it 'should be converted into gigabytes' do
						expect(config.qemu_disk_size).to eq('15')
					end
				end
			end
		end
	end
end