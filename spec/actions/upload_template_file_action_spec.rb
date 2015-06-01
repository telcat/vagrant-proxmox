require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::UploadTemplateFile do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_connection: connection, proxmox_selected_node: node} }
		let(:template_file) { 'template.tar.gz' }
		let(:template_file_exists) { true }
		let(:replace_template_file) { false }
		let(:node) { 'node1' }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before do
			env[:machine].provider_config.openvz_template_file = template_file
			env[:machine].provider_config.replace_openvz_template_file = replace_template_file
			allow(File).to receive(:exist?).with(template_file).and_return(template_file_exists)
		end

		context 'with a specified template file' do

			it 'should upload the template file into the local storage of the selected node' do
				expect(connection).to receive(:upload_file).with(template_file, content_type: 'vztmpl', node: node, storage: 'local', replace: replace_template_file)
				action.call env
			end
		end

		it 'should return :ok after a successful upload' do
			allow(connection).to receive(:upload_file).with(template_file, content_type: 'vztmpl', node: node, storage: 'local', replace: replace_template_file)
			action.call env
			expect(env[:result]).to eq(:ok)
		end

		context 'the template file should be replaced' do

			let(:replace_template_file) { true }

			it 'should delete the template file on the server' do
				expect(connection).to receive(:delete_file).with(filename: template_file, content_type: 'vztmpl', node: node, storage: 'local')
				action.call env
			end
		end

		context 'when a server error occurs' do

			before do
				allow(connection).to receive(:upload_file).and_raise ApiError::ServerError
			end

			it 'should return :server_error' do
				action.call env
				expect(env[:result]).to eq(:server_upload_error)
			end
		end

		context 'without a specified template file' do

			let(:template_file) { nil }

			it 'does nothing and returns OK' do
				expect(connection).not_to receive(:upload_file)
				action.call env
				expect(env[:result]).to eq(:ok)
			end
		end

		context 'the specified template file does not exist' do

			let (:template_file_exists) { false }

			it 'should return :file_not_found' do
				action.call env
				expect(env[:result]).to eq(:file_not_found)
			end
		end
	end
end
