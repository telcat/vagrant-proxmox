require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::SyncFolders do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox), ui: double('ui').as_null_object} }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

			before do
				env[:machine].stub(:ssh_info) { {host: '127.0.0.1', port: 22, username: 'vagrant', private_key_path: ['key']} }
				env[:machine].communicate.stub :sudo
				Vagrant::Util::Subprocess.stub :execute => Vagrant::Util::Subprocess::Result.new(0, nil, nil)
			end

			it_behaves_like 'a proxmox action call'

			it 'should print a message to the user interface' do
				expect(env[:ui]).to receive(:info).with("Rsyncing folder: #{Dir.pwd}/ => /vagrant")
				action.call env
			end

			it 'should create a directory on the vm with the predefined ownership' do
				expect(env[:machine].communicate).to receive(:sudo).with("mkdir -p '/vagrant'")
				expect(env[:machine].communicate).to receive(:sudo).with("chown vagrant '/vagrant'")
				action.call env
			end

			it 'should rsync the directory with the vm' do
				expect(Vagrant::Util::Subprocess).to receive(:execute).with(
																								 'rsync', '--verbose', '--archive', '--compress', '--delete',
																								 '-e', "ssh -p 22 -i 'key' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null",
																								 "#{Dir.pwd}/", 'vagrant@127.0.0.1:/vagrant')
				action.call env
			end

			it 'should raise an error if the rsync fails' do
				Vagrant::Util::Subprocess.stub :execute  => Vagrant::Util::Subprocess::Result.new(1, nil, nil)
				expect { action.call(env) }.to raise_error Errors::RsyncError
			end

		end

	end

end
