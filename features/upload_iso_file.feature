Feature: Use new iso file
  As a system administrator I want to choose an iso file to be uploaded to the proxmox server in order to
  use its contents for the virtual machine.

  Background:
    Given a Vagrantfile with these provider settings:
    """
      Vagrant.configure('2') do |config|
        config.vm.provider :proxmox do |proxmox|
          proxmox.endpoint = 'https://proxmox.example.com/api2/json'
          proxmox.user_name = 'vagrant'
          proxmox.password = 'password'
          proxmox.vm_type = :qemu
          proxmox.qemu_os = :l26
          proxmox.qemu_iso_file = './tmp/justanisofile.iso'
          proxmox.qemu_disk_size = '30G'
	      end
        config.vm.define :machine, primary: true do |machine|
          machine.vm.box = 'b681e2bc-617b-4b35-94fb-edc92e1071b8'
          machine.vm.network :public_network, ip: '172.16.100.1', macaddress: 'aa:bb:cc:dd:ee:ff'
        end
      end
    """

  Scenario: An iso file is specified in the Vagrantfile and does not exist on the proxmox server
    Given An iso file "./tmp/justanisofile.iso" exists locally
    When I run "vagrant up --provider=proxmox --no-provision"
    Then The iso file "./tmp/justanisofile.iso" is uploaded into the local storage of the vm node
    And the new virtual machine using the iso "local:iso/justanisofile.iso" is created

  Scenario: An iso file is specified in the Vagrantfile and already exists on the proxmox server
    Given An iso file "./tmp/justanisofile.iso" exists locally
    And the iso file "justanisofile.iso" exists locally" already exists in the proxmox storage
    When I run "vagrant up --provider=proxmox --no-provision"
    Then The iso file "./tmp/justanisofile.iso" is not uploaded
    And the new virtual machine using the iso "local:iso/justanisofile.iso" is created

  Scenario: An iso file is specified in the Vagrantfile but does not exist locally
    When I run "vagrant up --provider=proxmox --no-provision"
    Then I should see "File for upload not found"

  Scenario: An iso file is specified in the Vagrantfile and an error occurs during upload
    Given An iso file "./tmp/justanisofile.iso" exists locally
    But during upload an error will occur
    When I run "vagrant up --provider=proxmox --no-provision"
    Then I should see "Error during upload"