def up_machine
	@environment = Vagrant::Environment.new vagrantfile_name: 'dummy_box/Cucumber_Vagrantfile'
	@environment.instance_variable_set :@ui, @ui
	stub_remote_vagrant_call /mkdir/
	stub_remote_vagrant_call /chown/
	stub_local_vagrant_call /rsync/
	stub_remote_vagrant_call /chmod/
	stub_request(:post, proxmox_api_url('access/ticket')).
		to_return body: {data: {ticket: 'ticket', CSRFPreventionToken: 'token'}}.to_json
	stub_request(:get, proxmox_api_url('nodes')).
		to_return body: {data: [{node: 'node1'}]}.to_json
	stub_request(:get, proxmox_api_url('cluster/resources?type=vm')).
		to_return body: {data: []}.to_json
	stub_request(:post, proxmox_api_url('nodes/node1/openvz')).
		to_return body: {data: 'task_id'}.to_json
	stub_request(:get, proxmox_api_url('nodes/node1/tasks/task_id/status')).
		to_return body: {data: {exitstatus: 'OK'}}.to_json
	stub_request(:post, proxmox_api_url('nodes/node1/openvz/900/status/start')).
		to_return body: {data: 'task_id'}.to_json
	stub_request(:get, proxmox_api_url('nodes/node1/openvz/900/status/current')).
		to_return(body: {data: {status: 'running'}}.to_json)
	execute_vagrant_command :up, '--provider=proxmox' , '--no-provision'
	@ui.reset!
	WebMock.reset!
	VagrantProcessMock.reset_history!

	stub_request(:post, proxmox_api_url('access/ticket')).
		to_return body: {data: {ticket: 'ticket', CSRFPreventionToken: 'token'}}.to_json
	stub_request(:get, proxmox_api_url('nodes')).
		to_return body: {data: [{node: 'node1'}]}.to_json
	stub_request(:get, proxmox_api_url('cluster/resources?type=vm')).
		to_return body: {data: []}.to_json
	stub_request(:post, proxmox_api_url('nodes/node1/openvz')).
		to_return body: {data: 'task_id'}.to_json
	stub_request(:get, proxmox_api_url('nodes/node1/tasks/task_id/status')).
		to_return body: {data: {exitstatus: 'OK'}}.to_json
	stub_request(:post, proxmox_api_url('nodes/node1/openvz/900/status/shutdown')).
		to_return body: {data: 'task_id'}.to_json
	stub_request(:delete, proxmox_api_url('nodes/node1/openvz/900')).
		to_return body: {data: 'task_id'}.to_json
	stub_request(:post, proxmox_api_url('nodes/node1/openvz/900/status/start')).
		to_return body: {data: 'task_id'}.to_json
end

def proxmox_api_url path
	"https://proxmox.example.com/api2/json/#{path}"
end

def execute_vagrant_command command, *params
	Vagrant.plugin('2').manager.commands[command].new(params, @environment).execute
end

def add_dummy_box
	begin
		VagrantProcessMock.enabled = false
		Vagrant::Environment.new.boxes.add 'dummy_box/dummy.box', 'b681e2bc-617b-4b35-94fa-edc92e1071b8', :proxmox
		VagrantProcessMock.enabled = true
	rescue Vagrant::Errors::BoxAlreadyExists
	end
end

def remove_dummy_box
	@environment = Vagrant::Environment.new vagrantfile_name: 'dummy_box/Cucumber_Vagrantfile'
	execute_vagrant_command :box, 'remove', 'b681e2bc-617b-4b35-94fa-edc92e1071b8'
end
