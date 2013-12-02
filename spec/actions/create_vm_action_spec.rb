require 'spec_helper'
require 'actions/proxmox_action_shared'

describe VagrantPlugins::Proxmox::Action::CreateVm do

	it_behaves_like VagrantPlugins::Proxmox::Action::ProxmoxAction

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
							 proxmox_nodes: [{node: 'localhost'}],
							 ui: double('ui').as_null_object} }
	let(:app) { double('app').as_null_object }
	let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:vzcreate:100:vagrant@pve:' }

	subject { described_class.new(app, environment) }

	describe '#call' do

		before do
			allow(RestClient).to receive(:post).and_return({data: task_upid}.to_json)
			allow(subject).to receive(:get_free_vm_id).with(env).and_return(100)
			allow(subject).to receive(:wait_for_completion).and_return('OK')
		end

		it_behaves_like 'a proxmox action call'
		it_behaves_like 'a blocking proxmox action'

		describe 'the post request send to create a new virtual machine' do

			context 'with default config' do
				specify do
					RestClient.should_receive(:post).
							with('https://your.proxmox.server/api2/json/nodes/localhost/openvz',
									 {vmid: 100,
										hostname: 'box',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'},
									 anything).
							and_return({data: task_upid}.to_json)
					subject.call env
				end
			end

			context 'with a specified hostname' do
				before { env[:machine].config.vm.hostname = 'hostname' }
				specify do
					RestClient.should_receive(:post).
							with('https://your.proxmox.server/api2/json/nodes/localhost/openvz',
									 {vmid: 100,
										hostname: 'hostname',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'},
									 anything).
							and_return({data: task_upid}.to_json)
					subject.call env
				end
			end

			context 'with a specified ip address' do
				before { env[:machine].config.vm.stub(:networks) { [[:public_network, {ip: '127.0.0.1'}]] } }
				specify do
					RestClient.should_receive(:post).
							with('https://your.proxmox.server/api2/json/nodes/localhost/openvz',
									 {vmid: 100,
										hostname: 'box',
										ip_address: '127.0.0.1',
										ostemplate: 'local:vztmpl/template.tgz',
										password: 'vagrant',
										memory: 256,
										description: 'vagrant_test_box'},
									 anything).
							and_return({data: task_upid}.to_json)
					subject.call env
				end
			end

		end

		it 'should print a message to the user interface' do
			env[:ui].should_receive(:info).with 'Creating the virtual machine...'
			env[:ui].should_receive(:info).with 'Done!'
			subject.call env
		end

		it 'should store the node and vmid in env[:machine].id' do
			subject.call env
			env[:machine].id.should == 'localhost/100'
		end

		context 'when the proxmox server responds with an error to the create request' do

			let(:error_exit_status) { ["can't lock container 100", "close (rename) atomic file '/etc/pve/nodes/localhost/openvz/100.conf' failed: File exists"] }

			before { subject.stub :sleep }

			context 'when the proxmox server replies with an exit status describing the error' do
				it 'should create a virtual machine with another vmid' do
					expect(subject).to receive(:get_free_vm_id).with(env).twice.and_return(100, 101)
					expect(subject).to receive(:wait_for_completion).twice.and_return(error_exit_status.sample, 'OK')
					subject.call env
					env[:machine].id.should == 'localhost/101'
				end
			end

			context 'when the proxmox server replies with a "500 Internal Server Error"' do
				it 'should create a virtual machine with another vmid' do
					expect(subject).to receive(:get_free_vm_id).with(env).twice.and_return(100, 101)
					expect(subject).to receive(:wait_for_completion).and_raise(RestClient::InternalServerError).once
					expect(subject).to receive(:wait_for_completion).once.and_return('OK')
					subject.call env
					env[:machine].id.should == 'localhost/101'
				end
			end

			context 'when the create requests fail continuously before the timeout deadline is reached' do
				it 'should raise a VMCreationError' do
					expect(subject).to receive(:get_free_vm_id).with(env).exactly(30).times.and_return(100)
					expect(subject).to receive(:wait_for_completion).exactly(30).times.and_return(error_exit_status.sample)
					expect { subject.send :call, env }.to raise_error VagrantPlugins::Proxmox::Errors::VMCreationError
				end
			end

		end

	end

	describe '#get_free_vm_id' do

		it 'should query the proxmox server for all qemu and openvz machines' do
			RestClient.should_receive(:get).with('https://your.proxmox.server/api2/json/cluster/resources?type=vm', anything).and_return({data: []}.to_json)
			subject.send(:get_free_vm_id, env)
		end

		describe 'find the smallest unused vm_id in the configured range' do

			before { env[:machine].provider_config.vm_id_range = 3..4 }

			context 'when free vm_ids are available' do
				[
						{used_vm_ids: {data: []}, smallest_free_in_range: 3},
						{used_vm_ids: {data: [{vmid: 3}]}, smallest_free_in_range: 4},
						{used_vm_ids: {data: [{vmid: 1}]}, smallest_free_in_range: 3},
						{used_vm_ids: {data: [{vmid: 1}, {vmid: 3}]}, smallest_free_in_range: 4},
				].each do |example|
					it 'should return the smallest unused vm_id in the configured vm_id_range' do
						allow(RestClient).to receive(:get).and_return(example[:used_vm_ids].to_json)
						subject.send(:get_free_vm_id, env).should == example[:smallest_free_in_range]
					end
				end
			end

			context 'when no vm_ids are available' do
				it 'should throw a no_vm_id_available error' do
					allow(RestClient).to receive(:get).and_return({data: [{vmid: 1}, {vmid: 2}, {vmid: 3}, {vmid: 4}]}.to_json)
					expect { subject.send :get_free_vm_id, env }.to raise_error VagrantPlugins::Proxmox::Errors::NoVmIdAvailable
				end
			end

		end

	end

end
