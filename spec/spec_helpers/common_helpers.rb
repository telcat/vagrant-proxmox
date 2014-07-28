def be_called &action_stub
	ActionCallMatcher.new action_stub, environment, self, :called
end

def be_omitted &action_stub
	ActionCallMatcher.new action_stub, environment, self, :omitted
end

# If you want to expect your actions to be called (and optionally stub their call methods),
# use something like this:
#
#   let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
#
#   Action::ConnectProxmox.should be_called { |env| env[:proxmox_ticket] = 'ticket' }
#
class ActionCallMatcher < RSpec::Matchers::BuiltIn::BaseMatcher
	def initialize action_stub, environment, example_group, kind=:called
		super action_stub
		@environment = environment
		@example_group = example_group
		@kind = kind
	end

	def match(action_stub, action_class)
		@example_group.send(:mock_action, action_class).tap do |action|
			case @kind
				when :called
					@example_group.expect(action).to @example_group.receive(:call).at_least(:once) do |env|
						action_stub.call(env) if action_stub
						action.instance_variable_get(:@app).call env
					end
				when :omitted
					@example_group.expect(action).not_to @example_group.receive :call
			end
		end
	end
end

# If you want expectations on the action_class use something like:
#
#		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
#
#   mock_action(VagrantPlugins::Proxmox::Action::ConnectProxmox).tap do |action|
# 	  action.should receive(:perform) {|env| env[:proxmox_ticket] = 'ticket' }
#   end
#
def mock_action action_class, env = RSpec::Mocks::Double.new('env').as_null_object
	action_class.new(nil, env).tap do |action_instance|
		action_instance_name = "@#{action_class.name.demodulize}Action".underscore
		self.instance_variable_set action_instance_name, action_instance
		allow(action_class).to receive(:new) do |app, _|
			action_instance.instance_variable_set '@app', app
			action_instance
		end
	end
end

# If you want to stub your actions (stub their call methods), use something like this:
#
#   let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
#
#   stub_action(Action::ConnectProxmox) { |env| env[:proxmox_ticket] = 'ticket' }
#
def stub_action action_class
	mock_action(action_class).tap do |action|
		allow(action).to receive(:call) do |env|
			yield env if block_given?
			action.instance_variable_get(:@app).call env
		end
	end
end

def unstub_action action_class
	RSpec::Mocks.space.proxy_for(action_class).reset
end

def execute_vagrant_command environment, command, *params
	Vagrant.plugin('2').manager.commands[command].new(params, environment).execute
end

def up_local_box
	allow(Vagrant::UI::Interface).to receive_messages :new => ui
	stub_action(VagrantPlugins::Proxmox::Action::ConnectProxmox)
	stub_action(VagrantPlugins::Proxmox::Action::GetNodeList) { |env| env[:proxmox_nodes] = [{node: 'node1'}] }
	stub_action(VagrantPlugins::Proxmox::Action::IsCreated) { |env| env[:result] = false }
	stub_action(VagrantPlugins::Proxmox::Action::CreateVm) { |env| env[:machine].id = 'node1/100' }
	stub_action(VagrantPlugins::Proxmox::Action::StartVm)
	stub_action(VagrantPlugins::Proxmox::Action::SyncFolders)
	execute_vagrant_command environment, :up, '--provider=proxmox'
	unstub_action(VagrantPlugins::Proxmox::Action::ConnectProxmox)
	unstub_action(VagrantPlugins::Proxmox::Action::GetNodeList)
	unstub_action(VagrantPlugins::Proxmox::Action::IsCreated)
	unstub_action(VagrantPlugins::Proxmox::Action::CreateVm)
	unstub_action(VagrantPlugins::Proxmox::Action::StartVm)
	unstub_action(VagrantPlugins::Proxmox::Action::SyncFolders)
end

def proxmox_api_url path
	"https://proxmox.example.com/api2/json/#{path}"
end

def add_dummy_box
	begin
		Vagrant::Environment.new.boxes.add 'dummy_box/dummy.box', 'b681e2bc-617b-4b35-94fa-edc92e1071b8', :proxmox
	rescue Vagrant::Errors::BoxAlreadyExists
	end
end

def remove_dummy_box
	execute_vagrant_command Vagrant::Environment.new, :box, 'remove', 'b681e2bc-617b-4b35-94fa-edc92e1071b8'
end
