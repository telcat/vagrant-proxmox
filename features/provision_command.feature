Feature: VM Provisioning
  As a system administrator I want to provision a virtual machine on the proxmox server so that its
  deployment state matches its configuraton.

  Scenario: The virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is running
    When I run "vagrant provision"
    Then Vagrant provisions the virtual machine
    And the local project folder is synchronized with the virtual machine

  Scenario: A stopped virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant provision"
    Then I should see "VM must be running to execute this command."

  Scenario: The virtual machine does not exist on the proxmox server
    Given no proxmox virtual machine exists
    When I run "vagrant provision"
    Then I should see "The virtual machine is not created on the server"
