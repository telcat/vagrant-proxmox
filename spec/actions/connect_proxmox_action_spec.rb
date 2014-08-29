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
				env[:machine].provider_config.imgcopy_timeout = 99
				allow_any_instance_of(Connection).to receive :login
			end

			it_behaves_like 'a proxmox action call'

			it 'should store a connection object in env[:proxmox_connection]' do
				action.call env
				expect(connection.api_url).to eq(api_url)
			end

			describe 'sets the connection configuration parameters' do
				before { action.call env }
				specify { expect(connection.vm_id_range).to eq(500..555) }
				specify { expect(connection.task_timeout).to eq(123) }
				specify { expect(connection.task_status_check_interval).to eq(5) }
				specify { expect(connection.imgcopy_timeout).to eq(99) }
			end

			it 'should call the login function with credentials from configuration' do
				expect_any_instance_of(Connection).to receive(:login).with username: username, password: password
				action.call env
			end

			context 'when the server communication fails' do

				before { allow_any_instance_of(Connection).to receive(:login).and_raise ApiError::InvalidCredentials }

				it 'should raise an error' do
					expect { action.call env }.to raise_error Errors::CommunicationError
				end

			end

		end

	end

end
