require 'erb'

def create_vagrantfile content
	vagrantfile = Tempfile.new 'vagrantfile'
	vagrantfile.write content
	vagrantfile.flush
	vagrantfile
end

def prepare_and_stub_custom_environment settings
  stub_local_vagrant_call 'ps -o comm= 1'
	vagrantfile = create_vagrantfile settings
	@environment = Vagrant::Environment.new vagrantfile_name: vagrantfile.path
	@environment.instance_variable_set :@ui, @ui
	stub_machine_initialization
end
