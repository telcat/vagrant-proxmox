Feature: VM Shutdown
  As a system administrator I want to shut a virtual machine down (halt).

  Scenario: A running virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is running
    When I run "vagrant halt"
    Then the machine is no longer running
    And I should see "Shutting down the virtual machine..."

  Scenario: A stopped virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant halt"
    Then I should see "The virtual machine is already stopped"

  Scenario: The virtual machine does not exist on the proxmox server
    Given no proxmox virtual machine exists
    When I run "vagrant halt"
    Then I should see "The virtual machine is not created on the server!"