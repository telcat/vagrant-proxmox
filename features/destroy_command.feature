Feature: VM Destruction
  As a system administrator I want to destroy a virtual machine.

  Scenario: A running virtual machine exists on the proxmox server and the user confirms the destruction
    Given a proxmox virtual machine exists
    And it is running
    And I run "vagrant destroy" and answer the confirmation with "Y"
    Then the machine should not exist any longer
    And I should see "Shutting down the virtual machine..."
    And I should see "Destroying the virtual machine..."

  Scenario: A running virtual machine exists on the proxmox server and the user does not confirm the destruction
    Given a proxmox virtual machine exists
    And it is running
    When I run "vagrant destroy" and answer the confirmation with "n"
    Then the machine should still exist
    And it is still running

  Scenario: A stopped virtual machine exists on the proxmox server and the user confirms the destruction
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant destroy" and answer the confirmation with "Y"
    Then the machine should not exist any longer
    And I should see "Destroying the virtual machine..."

  Scenario: A stopped virtual machine exists on the proxmox server and the user does not confirm the destruction
    Given a proxmox virtual machine exists
    And it is stopped
    When I run "vagrant destroy" and answer the confirmation with "n"
    Then the machine should still exist

  Scenario: The virtual machine does not exist on the proxmox server
    Given no proxmox virtual machine exists
    When I run "vagrant destroy"
    Then I should see "The virtual machine is not created on the server!"
