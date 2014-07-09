require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::CleanupAfterDestroy do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }
	let(:ui) { double('ui').as_null_object }

	subject(:action) { described_class.new(-> (_) {}, environment) }

	it_behaves_like 'a proxmox action call'

	describe '#call', :need_box do
		it 'should delete the directory `.vagrant/[:machine].name`' do
			expect do
				action.call env
			end.to change{File.exists?(".vagrant/machines/#{env[:machine].name}/proxmox")}.to false
		end
	end

end
