require 'spec_helper'
require 'proxmox/rest_call_shared'
require 'tempfile'

module VagrantPlugins::Proxmox

	describe Connection do

		let(:api_url) { 'https://proxmox.example.com/api' }
		let(:username) { 'user' }
		let(:password) { 'password' }
		let(:ticket) { 'valid ticket' }
		let(:csrf_token) { 'csrf prevention token' }
		let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:task_type:100:vagrant@pve:' }
		let(:task_response) { {data: task_upid} }
		let(:params) { {} }
		let(:connection_opts) { {} }
		let(:task_timeout) { 40 }
		let(:task_status_check_interval) { 5 }
		let(:imgcopy_timeout) { 85 }
		let(:vm_type) { '' }
		let(:node) { 'localhost' }
		let(:machine_id) { '100' }
		let(:vm_info) { {type: vm_type, node: node, id: machine_id} }

		subject(:connection) { Connection.new api_url, connection_opts }

		describe 'contains a fix for RestClient header unescaping bug' do
			let(:request) { RestClient::Request.new method: :get, url: 'url', cookies: {key: '+%20%21'} }
			it 'should not unescape the cookies' do
				expect(request.make_headers({})['Cookie']).to eq('key=+%20%21')
			end
		end

		describe '#initialize' do

			describe '#api_url' do
				subject { super().api_url }
				it { is_expected.to eq(api_url) }
			end

			context 'with default values' do
				describe '#vm_id_range' do
					subject { super().vm_id_range }
					it { is_expected.to eq(900..999) }
				end

				describe '#task_timeout' do
					subject { super().task_timeout }
					it { is_expected.to eq(60) }
				end

				describe '#task_status_check_interval' do
					subject { super().task_status_check_interval }
					it { is_expected.to eq(2) }
				end

				describe '#imgcopy_timeout' do
					subject { super().imgcopy_timeout }
					it { is_expected.to eq(120) }
				end
			end

			context 'with custom values' do
				let(:connection_opts) { {vm_id_range: (500..599), task_timeout: 90, task_status_check_interval: 3, imgcopy_timeout: 83} }

				describe '#vm_id_range' do
					subject { super().vm_id_range }
					it { is_expected.to eq(500..599) }
				end

				describe '#task_timeout' do
					subject { super().task_timeout }
					it { is_expected.to eq(90) }
				end

				describe '#task_status_check_interval' do
					subject { super().task_status_check_interval }
					it { is_expected.to eq(3) }
				end

				describe '#imgcopy_timeout' do
					subject { super().imgcopy_timeout }
					it { is_expected.to eq(83) }
				end
			end
		end

		describe '#login' do

			before do
				allow(RestClient).to receive_messages :post => {data: {ticket: ticket, CSRFPreventionToken: csrf_token}}.to_json
			end

			it 'should call the REST API access/ticket' do
				expect(RestClient).to receive(:post).with("#{api_url}/access/ticket", {username: username, password: password}, anything)
				connection.login username: username, password: password
			end

			context 'with valid credentials' do
				it 'should store the access ticket token' do
					connection.login username: username, password: password
					expect(connection.ticket).to eq(ticket)
				end
				it 'should store the CSRF prevention token' do
					connection.login username: username, password: password
					expect(connection.csrf_token).to eq(csrf_token)
				end
			end

			context 'with invalid credentials' do
				it 'should raise an invalid credentials error' do
					allow(RestClient).to receive(:post).and_raise RestClient::InternalServerError
					expect do
						connection.login username: username, password: password
					end.to raise_error ApiError::InvalidCredentials
				end
			end

			context 'when a network error occurs' do
				it 'should raise a connection error' do
					allow(RestClient).to receive(:post).and_raise SocketError
					expect do
						connection.login username: username, password: password
					end.to raise_error ApiError::ConnectionError
				end
			end
		end

		describe '#get_node_list' do

			before { allow(RestClient).to receive_messages :get => {data: [{node: 'node1'}, {node: 'node2'}]}.to_json }

			it 'should request the node list' do
				expect(RestClient).to receive(:get).with("#{api_url}/nodes", anything)
				connection.get_node_list
			end

			it 'should return an array of nodes' do
				expect(connection.get_node_list).to eq(['node1', 'node2'])
			end
		end

		describe '#get_vm_state' do

			let(:status) { '' }

			before do
				allow(connection).to receive_messages :get_vm_info => vm_info
				allow(RestClient).to receive(:get).with("#{api_url}/nodes/localhost/#{vm_type}/#{machine_id}/status/current", anything).
															 and_return({data: {status: status}}.to_json)
			end

			context 'when the machine is an openvz container' do

				let(:vm_type) { 'openvz' }

				it 'should request a machine state' do
					expect(RestClient).to receive(:get).with("#{api_url}/nodes/localhost/openvz/100/status/current", anything)
					connection.get_vm_state(100)
				end

				context 'when the machine is stopped' do
					let(:status) { :stopped }
					it 'should return :stopped' do
						expect(connection.get_vm_state(100)).to eq(:stopped)
					end
				end

				context 'when the machine is running' do
					let(:status) { :running }
					it 'should return :running' do
						expect(connection.get_vm_state(100)).to eq(:running)
					end
				end
			end

			context 'when the machine is a qemu emulation' do

				let(:vm_type) { 'qemu' }

				it 'should request a machine state' do
					expect(RestClient).to receive(:get).with("#{api_url}/nodes/localhost/qemu/100/status/current", anything)
					connection.get_vm_state(100)
				end

				context 'when the machine is stopped' do
					let(:status) { :stopped }
					it 'should return :stopped' do
						expect(connection.get_vm_state(100)).to eq(:stopped)
					end
				end

				context 'when the machine is running' do
					let(:status) { :running }
					it 'should return :running' do
						expect(connection.get_vm_state(100)).to eq(:running)
					end
				end
			end

			context 'when the machine is not created' do

				before { allow(RestClient).to receive(:get).and_raise RestClient::InternalServerError }

				it 'should return :not_created' do
					expect(connection.get_vm_state(100)).to eq(:not_created)
				end
			end
		end

		describe '#get' do

			it_should_behave_like 'a rest api call', :get

			before { allow(RestClient).to receive_messages get: {data: {}}.to_json }

			context 'with valid parameters' do
				it 'should call the REST API with the correct parameters' do
					expect(RestClient).to receive(:get).with("#{api_url}/resource", anything)
					connection.send :get, '/resource'
				end
				it 'should send the authentication authorization ticket as a cookie' do
					allow_any_instance_of(Connection).to receive_messages ticket: ticket
					expect(RestClient).to receive(:get).with(anything, hash_including(cookies: {PVEAuthCookie: ticket}))
					connection.send :get, '/resource'
				end
				it 'should return the JSON parsed response data' do
					expect(RestClient).to receive_messages :get => ({data: 'some_response'}.to_json)
					response = connection.send :get, '/resource'
					expect(response).to eq({data: 'some_response'})
				end
			end
		end


		describe '#wait_for_completion' do

			it 'should get the task exit status' do
				expect(connection).to receive(:get_task_exitstatus).with(task_upid).and_return('OK')
				connection.send(:wait_for_completion, task_response: task_response, timeout_message: '')
			end

			context 'when the task is completed' do
				before { allow(connection).to receive_messages get_task_exitstatus: 'OK' }
				it 'should return the task exit status' do
					expect(connection.send(:wait_for_completion, task_response: task_response, timeout_message: '')).to eq('OK')
				end
			end

			context 'when the task times out' do

				before do
					Timecop.freeze
					allow(connection).to receive_messages :get_task_exitstatus => nil
					allow(connection).to receive_messages :task_timeout => task_timeout
					allow(connection).to receive_messages :imgcopy_timeout => imgcopy_timeout
					allow(connection).to receive_messages :task_status_check_interval => task_status_check_interval
					allow(connection).to receive(:sleep) { |duration| Timecop.travel(Time.now + duration) }
				end

				after do
					Timecop.return
				end

				it 'should raise an timeout error' do
					expect { connection.send(:wait_for_completion, task_response: task_response, timeout_message: '') }.to raise_error VagrantPlugins::Proxmox::Errors::Timeout
				end

				it 'should check the task status a given number of times' do
					task_iterations = task_timeout / task_status_check_interval + 1
					expect(connection).to receive(:get_task_exitstatus).exactly(task_iterations).times
					connection.send(:wait_for_completion, task_response: task_response, timeout_message: '') rescue nil
				end

				it 'should check the task status a given number of times' do
					task_iterations = task_timeout / task_status_check_interval + 1
					expect(connection).to receive(:get_task_exitstatus).exactly(task_iterations).times
					connection.send(:wait_for_completion, task_response: task_response, timeout_message: '') rescue nil
				end

				context 'when it is a regular task' do

					it 'should wait out the task_timeout' do
						connection.send(:wait_for_completion, task_response: task_response, timeout_message: '') rescue nil
						expect(Time).to have_elapsed task_timeout.seconds
					end
				end

				context 'when it is an upload task' do

					let(:task_upid) { 'UPID:localhost:0000F6EF:00F8E35F:E268CD3B:imgcopy:100:vagrant@pve:' }

					it 'should wait out the imgcopy_timeout' do
						connection.send(:wait_for_completion, task_response: task_response, timeout_message: '') rescue nil
						expect(Time).to have_elapsed imgcopy_timeout.seconds
					end
				end
			end
		end

		describe '#get_task_exitstatus' do

			it 'should request the task state from the proxmox server given in the task UPID' do
				expect(RestClient).to receive(:get).with("#{api_url}/nodes/localhost/tasks/#{task_upid}/status", anything).
																and_return({data: {}}.to_json)
				connection.send(:get_task_exitstatus, task_upid)
			end

			context 'the task has exited' do
				it 'should return the exit status' do
					allow(RestClient).to receive_messages get: {data: {upid: task_response, status: 'stopped', exitstatus: 'OK'}}.to_json
					expect(connection.send(:get_task_exitstatus, task_upid)).to eq('OK')
				end
			end

			context 'the task is still running' do
				it 'should return nil' do
					allow(RestClient).to receive_messages get: {data: {upid: task_response, status: 'running'}}.to_json
					expect(connection.send(:get_task_exitstatus, task_upid)).to eq(nil)
				end
			end
		end

		describe '#delete_vm' do

			before do
				allow(connection).to receive_messages :delete => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
				allow(connection).to receive_messages :get_vm_info => vm_info
			end

			context 'when the machine is an openvz container' do

				let(:vm_type) { 'openvz' }

				it 'should call delete with the node and vm as parameter' do
					expect(connection).to receive(:delete).with("/nodes/localhost/openvz/100")
					connection.delete_vm 100
				end

				it 'waits for completion of the server task' do
					expect(connection).to receive(:wait_for_completion)
					connection.delete_vm 100
				end

				it 'should return the task exit status' do
					expect(connection.delete_vm(100)).to eq('OK')
				end
			end

			context 'when the machine is a qemu emulation' do

				let(:vm_type) { 'qemu' }

				it 'should call delete with the node and vm as parameter' do
					expect(connection).to receive(:delete).with("/nodes/localhost/qemu/100")
					connection.delete_vm 100
				end

				it 'waits for completion of the server task' do
					expect(connection).to receive(:wait_for_completion)
					connection.delete_vm 100
				end

				it 'should return the task exit status' do
					expect(connection.delete_vm(100)).to eq('OK')
				end
			end
		end

		describe '#get_vm_type' do

			before do
				allow(RestClient).to receive(:get).with("#{api_url}/cluster/resources?type=vm", anything).
															 and_return({data: vm_list}.to_json)
			end
			let(:vm_list) { [{node: 'node', id: 'openvz/100'}, {node: 'anothernode', id: 'qemu/101'}] }

			it 'should return the correct vm_information' do
				expect(connection.send(:get_vm_info, 101)).to eq({id: 101, node: 'anothernode', type: 'qemu'})
			end

			context 'when the vm is not found' do
				it 'should return nil' do
					expect(connection.send(:get_vm_info, 105)).to be_nil
				end
			end
		end

		describe '#delete' do

			it_should_behave_like 'a rest api call', :delete

			before { allow(RestClient).to receive_messages delete: {data: {}}.to_json }

			it 'should send a post request that deletes the openvz container' do
				expect(RestClient).to receive(:delete).with("#{api_url}/nodes/localhost/openvz/100", anything)
				connection.send :delete, "/nodes/localhost/openvz/100"
			end
		end

		describe '#get_free_vm_id' do

			it 'should query the proxmox server for all qemu and openvz machines' do
				expect(RestClient).to receive(:get).with("#{api_url}/cluster/resources?type=vm", anything).and_return({data: []}.to_json)
				connection.get_free_vm_id
			end

			describe 'find the smallest unused vm_id in the configured range' do

				before { connection.vm_id_range = 3..4 }

				context 'when free vm_ids are available' do
					[
						{used_vm_ids: {data: []}, smallest_free_in_range: 3},
						{used_vm_ids: {data: [{vmid: 3}]}, smallest_free_in_range: 4},
						{used_vm_ids: {data: [{vmid: 1}]}, smallest_free_in_range: 3},
						{used_vm_ids: {data: [{vmid: 1}, {vmid: 3}]}, smallest_free_in_range: 4},
					].each do |example|
						it 'should return the smallest unused vm_id in the configured vm_id_range' do
							allow(RestClient).to receive_messages :get => example[:used_vm_ids].to_json
							expect(subject.send(:get_free_vm_id)).to eq(example[:smallest_free_in_range])
						end
					end
				end

				context 'when no vm_ids are available' do
					it 'should throw a no_vm_id_available error' do
						allow(RestClient).to receive_messages :get => {data: [{vmid: 1}, {vmid: 2}, {vmid: 3}, {vmid: 4}]}.to_json
						expect { subject.send :get_free_vm_id }.to raise_error Errors::NoVmIdAvailable
					end
				end
			end
		end

		describe '#create_vm' do

			before do
				allow(connection).to receive_messages :post => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				expect(connection).to receive(:post).with('/nodes/localhost/openvz', 'params')
				connection.create_vm node: 'localhost', vm_type: 'openvz', params: 'params'
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.create_vm node: 'localhost', vm_type: 'openvz', params: params
			end

			it 'should return the task exit status' do
				expect(connection.create_vm(node: 'localhost', vm_type: 'openvz', params: 'params')).to eq('OK')
			end
		end

		describe '#post' do

			it_should_behave_like 'a rest api call', :post

			before { allow(RestClient).to receive_messages post: {data: {}}.to_json }

			it 'should call the REST API with the correct parameters' do
				expect(RestClient).to receive(:post).with("#{api_url}/resource", params, anything)
				connection.send :post, '/resource', params
			end

			it 'should return the JSON parsed response data' do
				expect(RestClient).to receive(:post).and_return({data: 'some_response'}.to_json)
				response = connection.send :post, '/resource', params
				expect(response).to eq({data: 'some_response'})
			end

			describe 'sending ticket and token as part of the post request' do

				context 'when authorized' do
					it 'should send the authentication authorization ticket as a cookie and the csrf token' do
						allow_any_instance_of(Connection).to receive_messages ticket: ticket
						allow_any_instance_of(Connection).to receive_messages csrf_token: csrf_token
						expect(RestClient).to receive(:post).with(anything, anything, hash_including({CSRFPreventionToken: csrf_token, cookies: {PVEAuthCookie: ticket}}))
						connection.send :post, '/resource', params
					end
				end

				context 'when not authorized' do
					it 'it should send the request without ticket and token' do
						allow_any_instance_of(Connection).to receive_messages ticket: nil
						allow_any_instance_of(Connection).to receive_messages csrf_token: nil
						expect(RestClient).to receive(:post).with anything, anything, hash_not_including(:CSRFPreventionToken, :cookies)
						connection.send :post, '/resource', params
					end
				end
			end
		end

		describe '#start_vm' do

			before do
				allow(connection).to receive_messages :post => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
				allow(connection).to receive_messages :get_vm_info => vm_info
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.start_vm '100'
			end

			it 'should return the task exit status' do
				expect(connection.start_vm('100')).to eq('OK')
			end

			context 'when the machine is an openvz container' do

				let(:vm_type) { 'openvz' }

				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/openvz/100/status/start", nil)
					connection.start_vm '100'
				end
			end

			context 'when the machine is a qemu emulation' do

				let(:vm_type) { 'qemu' }

				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/qemu/100/status/start", nil)
					connection.start_vm '100'
				end
			end
		end

		describe '#stop_vm' do

			before do
				allow(connection).to receive_messages :post => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
				allow(connection).to receive_messages :get_vm_info => vm_info
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.stop_vm '100'
			end

			it 'should return the task exit status' do
				expect(connection.stop_vm('100')).to eq('OK')
			end

			context 'when the machine is an openvz container' do

				let(:vm_type) { 'openvz' }

				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/openvz/100/status/stop", nil)
					connection.stop_vm '100'
				end
			end

			context 'when the machine is a qemu emulation' do

				let(:vm_type) { 'qemu' }

				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/qemu/100/status/stop", nil)
					connection.stop_vm '100'
				end
			end
		end

		describe '#shutdown_vm' do

			before do
				allow(connection).to receive_messages :post => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
				allow(connection).to receive_messages :get_vm_info => vm_info
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.shutdown_vm '100'
			end

			it 'should return the task exit status' do
				expect(connection.shutdown_vm('100')).to eq('OK')
			end

			context 'when the machine is an openvz container' do

				let(:vm_type) { 'openvz' }

				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/openvz/100/status/shutdown", nil)
					connection.shutdown_vm '100'
				end
			end

			context 'when the machine is a qemu emulation' do

				let(:vm_type) { 'qemu' }
				it 'should call post with the correct parameters' do
					expect(connection).to receive(:post).with("/nodes/localhost/qemu/100/status/shutdown", nil)
					connection.shutdown_vm '100'
				end
			end
		end

		describe '#upload_file' do

			let (:file) { '/my/dir/template.tar.gz' }
			let (:replace_openvz_template_file) { false }
			let (:storage_file_list) { [] }

			before do
				allow(connection).to receive(:post)
				allow(File).to receive(:new).with(file, anything).and_return file
				allow(RestClient).to receive(:get).with("#{api_url}/nodes/localhost/storage/local/content", anything()).
															 and_return(({data: storage_file_list}).to_json)
				allow(connection).to receive_messages :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				expect(connection).to receive(:post).with('/nodes/localhost/storage/local/upload',
																									{:content => 'vztmpl', :filename => file, :node => 'localhost', :storage => 'local'})
				connection.upload_file file, content_type: 'vztmpl', node: 'localhost', storage: 'local'
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.upload_file file, content_type: 'vztmpl', node: 'localhost', storage: 'local'
			end

			it 'should return the task exit status' do
				expect(connection.upload_file file, content_type: 'vztmpl', node: 'localhost', storage: 'local').to eq('OK')
			end

			context 'when the file already exists in storage of the proxmox node' do

				let (:storage_file_list) { [{volid: 'local:vztmpl/template.tar.gz'}] }

				context 'when the file is not set to be replaced' do

					it 'should not upload the file' do
						expect(connection).not_to receive(:post).with('/nodes/localhost/storage/local/upload', anything())
						connection.upload_file file, content_type: 'vztmpl', node: 'localhost', storage: 'local'
					end
				end

				context 'when the file is set to be replaced' do

					let (:replace_openvz_template_file) { true }

					it 'should delete the file before upload' do
						expect(connection).to receive(:delete_file)
						connection.upload_file file, content_type: 'vztmpl', node: 'localhost', storage: 'local', replace: true
					end
				end
			end
		end

		describe '#delete_file' do

			let (:file) { '/my/dir/template.tar.gz' }
			let (:replace_openvz_template_file) { true }
			let (:storage_file_list) { [] }

			before do
				allow(connection).to receive_messages :post => {data: 'task_id'}.to_json
				allow(connection).to receive_messages :wait_for_completion => 'OK'
				allow(connection).to receive_messages :get_vm_info => vm_info
			end

			it 'waits for completion of the server task' do
				expect(connection).to receive(:wait_for_completion)
				connection.stop_vm '100'
			end

			it 'should return the task exit status' do
				expect(connection.stop_vm('100')).to eq('OK')
			end

			context 'the file exists in the storage' do

				let (:storage_file_list) { [{volid: 'local:vztmpl/template.tar.gz'}] }

				it 'should delete the file from the storage' do
					expect(connection).to receive(:delete).with("/nodes/localhost/storage/local/content/template.tar.gz")
					connection.delete_file filename: file, node: 'localhost', storage: 'local'
				end
			end

			context 'the file does not exist in the storage' do

			end
		end

		describe '#list_storage_files' do
			before do
				expect(RestClient).to receive(:get).with("#{api_url}/nodes/node1/storage/local/content", anything()).
																and_return(({data: [{volid: 'local:vztmpl/mytemplate.tar.gz'}]}).to_json)
			end

			it 'should return a list of the content of a storage' do
				res = connection.list_storage_files node: 'node1', storage: 'local'
				expect(res).to eq(['local:vztmpl/mytemplate.tar.gz'])
			end
		end
	end
end
