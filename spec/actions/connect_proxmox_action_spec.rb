require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::ConnectProxmox do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }

		subject { described_class.new(-> (_) {}, environment) }

		before { VagrantPlugins::Proxmox::Plugin.setup_i18n }

		describe '#call' do

			before do
				allow(RestClient).to receive(:post).and_return({data: {ticket: 'valid_ticket', CSRFPreventionToken: 'valid_token'}}.to_json)
			end

			it_behaves_like 'a proxmox action call'

			it 'should call the REST API access/ticket' do
				RestClient.should_receive(:post).with('https://your.proxmox.server/api2/json/access/ticket', {username: 'vagrant', password: 'password'})
				subject.call env
			end

			it 'should store the access ticket in env[:proxmox_ticket]' do
				subject.call env
				env[:proxmox_ticket].should == 'valid_ticket'
			end

			it 'should store the access ticket in env[:proxmox_csrf_prevention_token]' do
				subject.call env
				env[:proxmox_csrf_prevention_token].should == 'valid_token'
			end

			describe 'when the server communication fails' do
				before { RestClient.stub(:post).and_return nil }
				specify do
					expect { subject.call env }.to raise_error Errors::CommunicationError
				end
			end

		end

	end

end
