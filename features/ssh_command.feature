Feature: VM ssh
  As a system administrator I want use ssh with the virtual machine

  Scenario: A running virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is running
    When I run "vagrant ssh"
    Then an ssh shell should be provided

  Scenario: A stopped virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant ssh"
    Then I should see "VM must be running to execute this command."

  Scenario: The virtual machine does not exist on the proxmox server
    Given no proxmox virtual machine exists
    When I run "vagrant ssh"
    Then I should see "The virtual machine is not created on the server!"