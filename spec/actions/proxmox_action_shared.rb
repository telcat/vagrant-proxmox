shared_examples VagrantPlugins::Proxmox::Action::ProxmoxAction do

	let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile'}
	let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
							 proxmox_nodes: [{node: 'localhost'}]} }
	let(:task_upid) { 'UPID:localhost:0000F6ED:00F8E25F:5268CD3B:vzcreate:100:vagrant@pve:' }

	describe '#wait_for_completion' do

		context 'when the task is completed' do
			before { allow(subject).to receive(:get_task_exitstatus).and_return('OK') }
			it 'should return the tasks exit status' do
				subject.send(:wait_for_completion, task_upid, 'localhost', env, '').should == 'OK'
			end
		end

		context 'when the task times out' do
			before do
				allow(subject).to receive(:get_task_exitstatus).and_return(nil)
				Retryable.disable
			end
			it 'should raise an timeout error' do
				expect { subject.send(:wait_for_completion, task_upid, 'localhost', env, '') }.to raise_error VagrantPlugins::Proxmox::Errors::Timeout
			end
			after { Retryable.enable }
		end

	end

	describe '#get_task_exitstatus' do

		it 'should request the task state from the proxmox server' do
			RestClient.should_receive(:get).with("https://your.proxmox.server/api2/json/nodes/localhost/tasks/#{task_upid}/status", anything).
					and_return({data: {}}.to_json)
			subject.send(:get_task_exitstatus, task_upid, 'localhost', env)
		end

		context 'the task has exited' do
			it 'should return the exit status' do
				allow(RestClient).to receive(:get).and_return({data: {upid: task_upid, status: 'stopped', exitstatus: 'OK'}}.to_json)
				subject.send(:get_task_exitstatus, task_upid, 'localhost', env).should == 'OK'
			end
		end

		context 'the task is still running' do
			it 'should return nil' do
				allow(RestClient).to receive(:get).and_return({data: {upid: task_upid, status: 'running'}}.to_json)
				subject.send(:get_task_exitstatus, task_upid, 'localhost', env).should == nil
			end
		end

	end

end

shared_examples 'a proxmox action call' do

	describe 'when done' do
		it 'should call the next action' do
			expect(subject).to receive(:next_action).with env
			subject.call env
		end
	end

end

shared_examples 'a blocking proxmox action' do

	it 'waits for completion of the server task' do
		subject.should receive(:wait_for_completion)
		subject.call env
	end

end
