Feature: VM Startup
  As a system administrator I want to start a virtual machine (up).

  Scenario: A stopped virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant up"
    Then the machine is now running
    And I should see "Starting the virtual machine..."

  Scenario: A running virtual machine exists on the proxmox server
    Given a proxmox virtual machine exists
    And it is running
    When I run "vagrant up"
    Then I should see "The virtual machine is already up and running"

  Scenario: The virtual machine does not yet exist on the proxmox server
    Given no proxmox virtual machine exists
    When I run "vagrant up"
    Then the machine is now running
    And I should see "Creating the virtual machine..."