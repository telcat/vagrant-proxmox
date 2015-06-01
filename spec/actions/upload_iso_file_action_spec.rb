require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::UploadIsoFile do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile_qemu' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 proxmox_connection: connection, proxmox_selected_node: node} }
		let(:iso_file) { 'some_iso.iso' }
		let(:iso_file_exists) { true }
		let(:replace_iso_file) { false }
		let(:node) { 'node1' }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		before do
			env[:machine].provider_config.qemu_iso_file = iso_file
			env[:machine].provider_config.replace_qemu_iso_file = replace_iso_file
			allow(File).to receive(:exist?).with(iso_file).and_return(iso_file_exists)
		end

		context 'with a specified iso file' do

			it 'should upload the iso file into the local storage of the selected node' do
				expect(connection).to receive(:upload_file).with(iso_file, content_type: 'iso', node: node, storage: 'local', replace: false)
				action.call env
			end
		end

		it 'should return :ok after a successful upload' do
			allow(connection).to receive(:upload_file).with(iso_file, content_type: 'iso', node: node, storage: 'local', replace: false)
			action.call env
			expect(env[:result]).to eq(:ok)
		end

		context 'with a specified iso file and replace statement' do

			let(:replace_iso_file) { true }

			context 'the iso file exists on the server' do

				before do
					allow(connection).to receive(:is_file_in_storage?).with(filename: iso_file, node: node, storage: 'local').and_return(1)
				end

				it 'should delete the iso file on the server' do
					expect(connection).to receive(:delete_file).with(filename: iso_file, node: node, storage: 'local')
					action.call env
				end
			end

			context 'the iso file does not exist on the server' do

				before do
					allow(connection).to receive(:is_file_in_storage?).with(filename: iso_file, node: node, storage: 'local').and_return(nil)
				end

				it 'should not delete the iso file on the server' do
					expect(connection).not_to receive(:delete_file)
					action.call env
				end
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

		context 'without a specified iso file' do

			let(:iso_file) { nil }

			it 'does nothing and returns OK' do
				expect(connection).not_to receive(:upload_file)
				action.call env
				expect(env[:result]).to eq(:ok)
			end
		end

		context 'the specified iso file does not exist' do

			let (:iso_file_exists) { false }

			it 'should return :file_not_found' do
				action.call env
				expect(env[:result]).to eq(:file_not_found)
			end
		end
	end
end
