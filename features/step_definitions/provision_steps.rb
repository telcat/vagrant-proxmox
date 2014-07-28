Then(/^Vagrant provisions the virtual machine$/) do
	expect_remote_vagrant_call /\/tmp\/vagrant-shell/
end

Then(/^the local project folder is synchronized with the virtual machine$/) do
	expect_local_vagrant_call /rsync .+ #{Dir.pwd}\/ vagrant@172.16.100.1:\/vagrant/
end
