Feature: Use existing template file
  As a system administrator I want to choose an existing template to generate the filesystem of the virtual machine.

  Scenario:
    Given a Vagrantfile with these provider settings:
    """
      Vagrant.configure('2') do |config|
        config.vm.provider :proxmox do |proxmox|
          proxmox.endpoint = 'https://proxmox.example.com/api2/json'
          proxmox.user_name = 'vagrant'
          proxmox.password = 'password'
          proxmox.os_template = 'local:vztmpl/template.tar.gz'
	      end
        config.vm.define :machine, primary: true do |machine|
          machine.vm.box = 'b681e2bc-617b-4b35-94fa-edc92e1071b8'
          machine.vm.network :public_network, ip: '172.16.100.1'
        end
      end
    """
    When I run "vagrant up --provider=proxmox --no-provision"
    Then the new virtual machine using the template "local:vztmpl/template.tar.gz" is created

