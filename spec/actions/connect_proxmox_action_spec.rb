require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::ConnectProxmox do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox)} }
		let(:api_url) { 'http://your.proxmox.machine/api' }
		let(:username) { 'user' }
		let(:password) { 'password' }
		let(:connection) { env[:proxmox_connection] }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before { VagrantPlugins::Proxmox::Plugin.setup_i18n }

		describe '#call' do

			before do
				env[:machine].provider_config.endpoint = api_url
				env[:machine].provider_config.user_name = username
				env[:machine].provider_config.password = password
				env[:machine].provider_config.vm_id_range = 500..555
				env[:machine].provider_config.task_timeout = 123
				env[:machine].provider_config.task_status_check_interval = 5
				Connection.any_instance.stub :login
			end

			it_behaves_like 'a proxmox action call'

			it 'should store a connection object in env[:proxmox_connection]' do
				action.call env
				connection.api_url.should == api_url
			end

			describe 'sets the connection configuration parameters' do
				before { action.call env }
				specify { connection.vm_id_range.should == (500..555) }
				specify { connection.task_timeout.should == 123 }
				specify { connection.task_status_check_interval.should == 5 }
			end

			it 'should call the login function with credentials from configuration' do
				Connection.any_instance.should_receive(:login).with username: username, password: password
				action.call env
			end

			context 'when the server communication fails' do

				before { Connection.any_instance.stub(:login).and_raise ApiError::InvalidCredentials }

				it 'should raise an error' do
					expect { action.call env }.to raise_error Errors::CommunicationError
				end

			end

		end

	end

end
