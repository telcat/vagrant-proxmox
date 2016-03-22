Given(/^a proxmox virtual machine exists$/) do
	up_machine
end

Given(/^no proxmox virtual machine exists$/) do
	up_machine
	stub_request(:get, proxmox_api_url('/nodes/node1/openvz/900/status/current')).
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
	stub_request(:get, proxmox_api_url('/nodes/node1/openvz/900/status/current')).
		to_return(body: {data: {status: 'running'}}.to_json)
end

And(/^it is stopped$/) do
	stub_request(:get, proxmox_api_url('/nodes/node1/openvz/900/status/current')).
		to_return(body: {data: {status: 'stopped'}}.to_json)
end

Then(/^I should see "([^"]*)"$/) do |text|
	expect_vagrant_ui_message /#{text}/
end

Then(/^the machine should not exist any longer$/) do
	assert_requested :delete, proxmox_api_url('/nodes/node1/openvz/900')
end

Then(/^the machine should still exist$/) do
	assert_not_requested :delete, proxmox_api_url('/nodes/node1/openvz/900')
end

And(/^it is still running$/) do
	assert_not_requested :post, proxmox_api_url('/nodes/node1/openvz/900/status/shutdown')
end

Then(/^the machine is no longer running$/) do
	assert_requested :post, proxmox_api_url('/nodes/node1/openvz/900/status/shutdown')
end

Then(/^the machine is now running$/) do
	assert_requested :post, proxmox_api_url('/nodes/node1/openvz/900/status/start')
end

Then(/^Vagrant provisions the virtual machine$/) do
	expect_remote_vagrant_call /\/tmp\/vagrant-shell/
end

Then(/^the local project folder is synchronized with the virtual machine$/) do
	expect_local_vagrant_call /rsync .+ #{Dir.pwd}\/ vagrant@172.16.100.1:\/vagrant/
end

Then(/^an ssh shell should be provided$/) do
	expect_vagrant_ssh_command ""
end

Then(/^the "([^"]*)" command is executed using ssh$/) do |command|
	expect_vagrant_ssh_command /#{command}/
end

Given(/^a Vagrantfile with these provider settings:$/) do |settings|
	prepare_and_stub_custom_environment settings
end

Then(/^the new virtual machine using the template "([^"]*)" is created$/) do |template|
	assert_requested :post, proxmox_api_url('/nodes/node1/openvz'), body: /#{CGI.escape(template)}/
end

Then(/^The template file "([^"]*)" is uploaded into the local storage of the vm node$/) do |filename|
	assert_requested :post, proxmox_api_url('/nodes/node1/storage/local/upload')
end

Then(/^The template file "([^"]*)" is not uploaded$/) do |filename|
	assert_not_requested :post, proxmox_api_url('/nodes/node1/storage/local/upload')
end

Given(/^the template file "([^"]*)" already exists in the proxmox storage$/) do |template|
	remove_request_stub @storage_content_request_stub
	@storage_content_request_stub = stub_request(:get, proxmox_api_url('/nodes/node1/storage/local/content')).
		to_return(body: {data: [{volid: "local:vztmpl/#{template}"}]}.to_json)
end

Given(/^A templatefile "([^"]*)" exists locally$/) do |filename|
	touch_tempfile filename
end

But(/^during upload an error will occur$/) do
	stub_request(:post, proxmox_api_url('/nodes/node1/storage/local/upload')).
		to_return status: 500
end

Then(/^(\d+) seconds should have passed$/) do |interval|
	expect(Time).to have_elapsed interval.to_i.seconds
end

And(/^it won't response to ssh once it's started$/) do
	CommunicatorMock.ssh_enabled = false
end

Given(/^An iso file "([^"]*)" exists locally$/) do |filename|
	touch_tempfile filename
end

Then(/^The iso file "([^"]*)" is uploaded into the local storage of the vm node$/) do |_|
	assert_requested :post, proxmox_api_url('/nodes/node1/storage/local/upload')
end

And(/^the new virtual machine using the iso "([^"]*)" is created$/) do |iso|
	assert_requested :post, proxmox_api_url('/nodes/node1/qemu'), body: /#{CGI.escape(iso)}/
end

And(/^the iso file "([^"]*)" already exists in the proxmox storage$/) do |iso|
	remove_request_stub @storage_content_request_stub
	@storage_content_request_stub = stub_request(:get, proxmox_api_url('/nodes/node1/storage/local/content')).
		to_return(body: {data: [{volid: "local:iso/#{iso}"}]}.to_json)
end

Then(/^The iso file "([^"]*)" is not uploaded$/) do |_|
	assert_not_requested :post, proxmox_api_url('/nodes/node1/storage/local/upload')
end

Then(/^The iso file "([^"]*)" is deleted from proxmox$/) do |iso|
	assert_requested :delete, proxmox_api_url("/nodes/node1/storage/local/content/iso/#{iso}")
end

Then(/^The template file "([^"]*)" is deleted from proxmox$/) do |template|
	assert_requested :delete, proxmox_api_url("/nodes/node1/storage/local/content/vztmpl/#{template}")
end