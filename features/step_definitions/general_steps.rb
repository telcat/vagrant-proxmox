Given(/^a proxmox virtual machine exists$/) do
	up_machine
end

Given(/^no proxmox virtual machine exists$/) do
	up_machine
	stub_request(:get, proxmox_api_url('nodes/node1/openvz/900/status/current')).
		to_return(status: 500)
end

When(/^I run "vagrant (\w+)(?:\s)?([^"]*)?"$/) do |command, params|
	execute_vagrant_command command.to_sym, *(params.split)
end

When(/^I run "vagrant (\w+)(?:\s)?([^"]*)?" and answer the confirmation with "(\w+)"$/) do |command, params, answer|
	stub_ui_input answer
	execute_vagrant_command command.to_sym, *(params.split)
end

And(/^it is running$/) do
	stub_request(:get, proxmox_api_url('nodes/node1/openvz/900/status/current')).
		to_return(body: {data: {status: 'running'}}.to_json)
end

And(/^it is stopped$/) do
	stub_request(:get, proxmox_api_url('nodes/node1/openvz/900/status/current')).
		to_return(body: {data: {status: 'stopped'}}.to_json)
end

Then(/^I should see "([^"]*)"$/) do |text|
	expect_vagrant_ui_message /#{text}/
end

Then(/^the machine should not exist any longer$/) do
	assert_requested(:delete, proxmox_api_url('nodes/node1/openvz/900'))
end

Then(/^the machine should still exist$/) do
	assert_not_requested(:delete, proxmox_api_url('nodes/node1/openvz/900'))
end

And(/^it is still running$/) do
	assert_not_requested(:post, proxmox_api_url('nodes/node1/openvz/900/status/shutdown'))
end

Then(/^the machine is no longer running$/) do
	assert_requested(:post, proxmox_api_url('nodes/node1/openvz/900/status/shutdown'))
end

Then(/^the machine is now running$/) do
	assert_requested(:post, proxmox_api_url('nodes/node1/openvz/900/status/start'))
end

Then(/^an ssh shell should be provided$/) do
	expect_vagrant_ssh_command ""
end

Then(/^the "([^"]*)" command is executed using ssh$/) do |command|
	expect_vagrant_ssh_command /'#{command}'/
end