Feature: Use new template file
  As a system administrator I want to choose a template file to be uploaded to the proxmox server in order to
  generate the filesystem of the virtual machine.

  Background:
    Given a Vagrantfile with these provider settings:
    """
      Vagrant.configure('2') do |config|
        config.vm.provider :proxmox do |proxmox|
          proxmox.endpoint = 'https://proxmox.example.com/api2/json'
          proxmox.user_name = 'vagrant'
          proxmox.password = 'password'
          proxmox.template_file = './tmp/mytemplate.tar.gz'
	      end
        config.vm.define :machine, primary: true do |machine|
          machine.vm.box = 'b681e2bc-617b-4b35-94fa-edc92e1071b8'
          machine.vm.network :public_network, ip: '172.16.100.1'
        end
      end
    """

  Scenario: A template is specified in the Vagrantfile and does not exist on the proxmox server
    Given A templatefile "./tmp/mytemplate.tar.gz" exists locally
    When I run "vagrant up --provider=proxmox --no-provision"
    Then The template file "./tmp/mytemplate.tar.gz" is uploaded into the local storage of the vm node
    And the new virtual machine using the template "local:vztmpl/mytemplate.tar.gz" is created

  Scenario: A template is specified in the Vagrantfile and already exists on the proxmox server
    Given A templatefile "./tmp/mytemplate.tar.gz" exists locally
    And the template file "mytemplate.tar.gz" already exists in the proxmox storage
    When I run "vagrant up --provider=proxmox --no-provision"
    Then The template file "./tmp/mytemplate.tar.gz" is not uploaded
    And the new virtual machine using the template "local:vztmpl/mytemplate.tar.gz" is created

  Scenario: A template is specified in the Vagrantfile but does not exist locally
    When I run "vagrant up --provider=proxmox --no-provision"
    Then I should see "File for upload not found"

  Scenario: A template is specified in the Vagrantfile and an error occurs during upload
    Given A templatefile "./tmp/mytemplate.tar.gz" exists locally
    But during upload an error will occure
    When I run "vagrant up --provider=proxmox --no-provision"
    Then I should see "Error during upload"