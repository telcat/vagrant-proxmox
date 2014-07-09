require 'spec_helper'
require 'proxmox/rest_call_shared_spec'

module VagrantPlugins::Proxmox

	describe Connection do

		let(:api_url) { 'https://your.proxmox.server/api' }
		let(:username) { 'user' }
		let(:password) { 'password' }
		let(:ticket) { 'valid ticket' }
		let(:csrf_token) { 'csrf prevention token' }
		let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:vzcreate:100:vagrant@pve:' }
		let(:task_response) { {data: task_upid} }
		let(:params) { { } }
		let(:connection_opts) { {} }

		subject(:connection) { Connection.new api_url, connection_opts }

		describe 'contains a fix for RestClient header unescaping bug' do
			let(:request) { RestClient::Request.new method: :get, url: 'url', cookies: {key: '+%20%21'} }
			it 'should not unescape the cookies' do
				request.make_headers({})['Cookie'].should == 'key=+%20%21'
			end
		end

		describe '#initialize' do

			its(:api_url) { should == api_url }

			context 'with default values' do
				its(:vm_id_range) { should == (900..999) }
				its(:task_timeout) { should == 60 }
				its(:task_status_check_interval) { should == 2 }
			end

			context 'with custom values' do
				let(:connection_opts) { {vm_id_range: (500..599), task_timeout: 90, task_status_check_interval: 3} }
				its(:vm_id_range) { should == (500..599) }
				its(:task_timeout) { should == 90 }
				its(:task_status_check_interval) { should == 3 }
			end
		end

		describe '#login' do
			before do
				RestClient.stub :post => {data: {ticket: ticket, CSRFPreventionToken: csrf_token}}.to_json
			end

			it 'should call the REST API access/ticket' do
				RestClient.should_receive(:post).with("#{api_url}/access/ticket", {username: username, password: password}, anything)
				connection.login username: username, password: password
			end

			context 'with valid credentials' do
				it 'should store the access ticket token' do
					connection.login username: username, password: password
					connection.ticket.should == ticket
				end
				it 'should store the CSRF prevention token' do
					connection.login username: username, password: password
					connection.csrf_token.should == csrf_token
				end
			end

			context 'with invalid credentials' do
				it 'should raise an invalid credentials error' do
					RestClient.stub(:post).and_raise RestClient::InternalServerError
					expect do
						connection.login username: username, password: password
					end.to raise_error ApiError::InvalidCredentials
				end
			end

			context 'when a network error occurs' do
				it 'should raise a connection error' do
					RestClient.stub(:post).and_raise SocketError
					expect do
						connection.login username: username, password: password
					end.to raise_error ApiError::ConnectionError
				end
			end

		end

		describe '#get_node_list' do

			before { RestClient.stub :get => {data: [{node: 'node1'}, {node: 'node2'}]}.to_json }

			it 'should request the node list' do
				RestClient.should_receive(:get).with("#{api_url}/nodes", anything)
				connection.get_node_list
			end

			it 'should return an array of nodes' do
				connection.get_node_list.should == ['node1', 'node2']
			end
		end

		describe '#get_vm_state' do

			let(:status) { '' }
			before { RestClient.stub :get => {data: {status: status}}.to_json }

			it 'should request a machine state' do
				RestClient.should_receive(:get).with("#{api_url}/nodes/node/openvz/100/status/current", anything)
				connection.get_vm_state(node: 'node', vm_id: '100')
			end

			context 'when the machine is not created' do
				before { RestClient.stub(:get).and_raise RestClient::InternalServerError }
				it 'should return :not_created' do
					connection.get_vm_state(node: 'node', vm_id: '100').should == :not_created
				end
			end

			context 'when the machine is stopped' do
				let(:status) { :stopped }
				it 'should return :stopped' do
					connection.get_vm_state(node: 'node', vm_id: '100').should == :stopped
				end
			end

			context 'when the machine is running' do
				let(:status) { :running }
				it 'should return :running' do
					connection.get_vm_state(node: 'node', vm_id: '100').should == :running
				end
			end

		end

		describe '#get' do

			it_should_behave_like 'a rest api call', :delete

			before { RestClient.stub get: {data: {}}.to_json }

			context 'with valid parameters' do
				it 'should call the REST API with the correct parameters' do
					RestClient.should_receive(:get).with("#{api_url}/resource", anything)
					connection.send :get, '/resource'
				end
				it 'should send the authentication authorization ticket as a cookie' do
					Connection.any_instance.stub ticket: ticket
					RestClient.should_receive(:get).with(anything, hash_including(cookies: {PVEAuthCookie: ticket}))
					connection.send :get, '/resource'
				end
				it 'should return the JSON parsed response data' do
					RestClient.should_receive(:get).and_return({data: 'some_response'}.to_json)
					response = connection.send :get, '/resource'
					response.should == {data: 'some_response'}
				end
			end

		end

		describe '#wait_for_completion' do

			it 'should get the task exit status' do
				connection.should_receive(:get_task_exitstatus).with(task_upid, anything).and_return('OK')
				connection.send(:wait_for_completion, task_response: task_response, node: 'localhost', timeout_message: '')
			end

			context 'when the task is completed' do
				before { connection.stub get_task_exitstatus: 'OK' }
				it 'should return the task exit status' do
					connection.send(:wait_for_completion, task_response: task_response, node: 'localhost', timeout_message: '').should == 'OK'
				end
			end

			context 'when the task times out' do

				before do
					Timecop.freeze
					connection.stub :get_task_exitstatus => nil
					connection.stub :task_timeout => 40
					connection.stub :task_status_check_interval => 5
					connection.stub(:sleep) { |duration| Timecop.travel(Time.now + 5) }
				end

				after do
					Timecop.return
				end

				it 'should raise an timeout error' do
					expect { connection.send(:wait_for_completion, task_response: task_response, node: 'localhost', timeout_message: '') }.to raise_error VagrantPlugins::Proxmox::Errors::Timeout
				end

				it 'should wait out the timeout' do
					connection.send(:wait_for_completion, task_response: task_response, node: 'localhost', timeout_message: '') rescue nil
					Time.should have_elapsed 40.seconds
				end

				it 'should check the task status many times' do
					connection.should_receive(:get_task_exitstatus).exactly(9).times
					connection.send(:wait_for_completion, task_response: task_response, node: 'localhost', timeout_message: '') rescue nil
				end

			end

		end

		describe '#get_task_exitstatus' do

			it 'should request the task state from the proxmox server' do
				RestClient.should_receive(:get).with("#{api_url}/nodes/localhost/tasks/#{task_response}/status", anything).
					and_return({data: {}}.to_json)
				connection.send(:get_task_exitstatus, task_response, 'localhost')
			end

			context 'the task has exited' do
				it 'should return the exit status' do
					RestClient.stub get: {data: {upid: task_response, status: 'stopped', exitstatus: 'OK'}}.to_json
					connection.send(:get_task_exitstatus, task_response, 'localhost').should == 'OK'
				end
			end

			context 'the task is still running' do
				it 'should return nil' do
					RestClient.stub get: {data: {upid: task_response, status: 'running'}}.to_json
					connection.send(:get_task_exitstatus, task_response, 'localhost').should == nil
				end
			end

		end

		describe '#delete_vm' do

			before do
				connection.stub :delete => {data: 'task_id'}.to_json
				connection.stub :wait_for_completion => 'OK'
			end

			it 'should call delete with the node and vm as parameter' do
				connection.should_receive(:delete).with('/nodes/localhost/openvz/100')
				connection.delete_vm node: 'localhost', vm_id: 100
			end

			it 'waits for completion of the server task' do
				connection.should_receive(:wait_for_completion)
				connection.delete_vm node: 'localhost', vm_id: 100
			end

			it 'should return the task exit status' do
				connection.delete_vm(node: 'localhost', vm_id: 100).should == 'OK'
			end

		end

		describe '#delete' do

			it_should_behave_like 'a rest api call', :delete

			before { RestClient.stub delete: {data: {}}.to_json }

			it 'should send a post request that deletes the openvz container' do
				RestClient.should_receive(:delete).with("#{api_url}/nodes/localhost/openvz/100", anything)
				connection.send :delete, "/nodes/localhost/openvz/100"
			end

		end

		describe '#get_free_vm_id' do

			it 'should query the proxmox server for all qemu and openvz machines' do
				RestClient.should_receive(:get).with("#{api_url}/cluster/resources?type=vm", anything).and_return({data: []}.to_json)
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
							RestClient.stub :get => example[:used_vm_ids].to_json
							subject.send(:get_free_vm_id).should == example[:smallest_free_in_range]
						end
					end
				end

				context 'when no vm_ids are available' do
					it 'should throw a no_vm_id_available error' do
						RestClient.stub :get => {data: [{vmid: 1}, {vmid: 2}, {vmid: 3}, {vmid: 4}]}.to_json
						expect { subject.send :get_free_vm_id }.to raise_error Errors::NoVmIdAvailable
					end
				end

			end

		end

		describe '#create_vm' do

			before do
				connection.stub :post => {data: 'task_id'}.to_json
				connection.stub :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				connection.should_receive(:post).with('/nodes/localhost/openvz', 'params')
				connection.create_vm node: 'localhost', params: 'params'
			end

			it 'waits for completion of the server task' do
				connection.should_receive(:wait_for_completion)
				connection.create_vm node: 'localhost', params: params
			end

			it 'should return the task exit status' do
				connection.create_vm(node: 'localhost', params: 'params').should == 'OK'
			end

		end

		describe '#post' do

			it_should_behave_like 'a rest api call', :post

			before { RestClient.stub post: {data: {}}.to_json }

			it 'should call the REST API with the correct parameters' do
				RestClient.should_receive(:post).with("#{api_url}/resource", params, anything)
				connection.send :post, '/resource', params
			end

			it 'should return the JSON parsed response data' do
				RestClient.should_receive(:post).and_return({data: 'some_response'}.to_json)
				response = connection.send :post, '/resource', params
				response.should == {data: 'some_response'}
			end

			describe 'sending ticket and token as part of the post request' do

				context 'when authorized' do
					it 'should send the authentication authorization ticket as a cookie and the csrf token' do
						Connection.any_instance.stub ticket: ticket
						Connection.any_instance.stub csrf_token: csrf_token
						RestClient.should_receive(:post).with(anything, anything, hash_including({CSRFPreventionToken: csrf_token, cookies: {PVEAuthCookie: ticket}}))
						connection.send :post, '/resource', params
					end
				end

				context 'when not autorized' do
					it 'it should send the request without ticket and token' do
						Connection.any_instance.stub ticket: nil
						Connection.any_instance.stub csrf_token: nil
						RestClient.should_receive(:post).with anything, anything, hash_not_including(:CSRFPreventionToken, :cookies)
						connection.send :post, '/resource', params
					end
				end

			end

		end

		describe '#start_vm' do

			before do
				connection.stub :post => {data: 'task_id'}.to_json
				connection.stub :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				connection.should_receive(:post).with("/nodes/localhost/openvz/100/status/start", nil)
				connection.start_vm node: 'localhost', vm_id: '100'
			end

			it 'waits for completion of the server task' do
				connection.should_receive(:wait_for_completion)
				connection.start_vm node: 'localhost', vm_id: '100'
			end

			it 'should return the task exit status' do
				connection.start_vm(node: 'localhost', vm_id: '100').should == 'OK'
			end

		end

		describe '#stop_vm' do

			before do
				connection.stub :post => {data: 'task_id'}.to_json
				connection.stub :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				connection.should_receive(:post).with("/nodes/localhost/openvz/100/status/stop", nil)
				connection.stop_vm node: 'localhost', vm_id: '100'
			end

			it 'waits for completion of the server task' do
				connection.should_receive(:wait_for_completion)
				connection.stop_vm node: 'localhost', vm_id: '100'
			end

			it 'should return the task exit status' do
				connection.stop_vm(node: 'localhost', vm_id: '100').should == 'OK'
			end

		end

		describe '#shutdown_vm' do

			before do
				connection.stub :post => {data: 'task_id'}.to_json
				connection.stub :wait_for_completion => 'OK'
			end

			it 'should call post with the correct parameters' do
				connection.should_receive(:post).with("/nodes/localhost/openvz/100/status/shutdown", nil)
				connection.shutdown_vm node: 'localhost', vm_id: '100'
			end

			it 'waits for completion of the server task' do
				connection.should_receive(:wait_for_completion)
				connection.shutdown_vm node: 'localhost', vm_id: '100'
			end

			it 'should return the task exit status' do
				connection.shutdown_vm(node: 'localhost', vm_id: '100').should == 'OK'
			end

		end

	end

end
