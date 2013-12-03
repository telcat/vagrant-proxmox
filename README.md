# Vagrant Proxmox Provider

This is a [Vagrant](http://www.vagrantup.com) 1.3+ plugin that adds a
[Proxmox](http://proxmox.com/) provider to Vagrant, allowing Vagrant to manage
and provision Proxmox virtual machines.

## Features

* Create/Destroy OpenVZ containers from specified templates
* Start/Shutdown OpenVZ containers
* SSH into virtual machine
* Provision the virtual machine
* Synced folder support via rsync

## Limitations

* Only OpenVZ containers are currently supported
* You need a Vagrant compatible OpenVZ template
* Only routed network mode is currently supported

## Installation

Install using standard Vagrant plugin method:

```
$ vagrant plugin install vagrant-vsphere
```

This will install the plugin from [RubGems.org](http://rubygems.org/).

## Usage

First install the provided dummy vagrant box:

```
$ vagrant box add dummy dummy_box/dummy.box
```

Then create a Vagrantfile that looks like the following:

```
Vagrant.configure('2') do |config|

	config.vm.provider :proxmox do |proxmox|
		proxmox.endpoint = 'https://your.proxmox.server/api2/json'
		proxmox.user_name = 'vagrant'
		proxmox.password = 'password'
		proxmox.vm_id_range = 900..910
		proxmox.vm_name_prefix = 'vagrant_'
		proxmox.os_template = 'local:vztmpl/template.tgz'
		proxmox.vm_memory = 256
		proxmox.task_timeout = 30
		proxmox.task_status_check_interval = 1
	end

	config.vm.define :box, primary: true do |box|
 		box.vm.box = 'dummy'
 	end

end
```

For the meaning of the various options, refer to the `Options` section below.

You need an OpenVZ template that contains a vagrant user supplied with the default Vagrant SSH keys.
You can download an example Ubuntu based template [here](https://www.dropbox.com/s/vuzywdosxhjjsag/vagrant-proxmox-ubuntu-12.tar.gz).

Finally run `vagrant up --provider=proxmox` to create and start the new OpenVZ container.

## Options

* `endpoint` URL of the JSON API endpoint of your Proxmox installation
* `user_name` The name of the Proxmox user that Vagrant should use
* `password` The password of the above user
* `vm_id_range` The possible range of machine ids. The smallest free one is chosen for a new machine
* `vm_name_prefix` An optional string that is prepended before the vm name
* `os_template` The name of the template from which the OpenVZ container should be created
* `vm_memory` The container's main memory size
* `task_timeout` How long to wait for completion of a Proxmox API command (in seconds)
* `task_status_check_interval` Interval in seconds between checking for completion of a Proxmox API command

## Build the plugin

Build the plugin gem with

```
$ rake build
```

Optionally run the rspec tests with


```
$ rake spec
```

## About us

[TELCAT MULTICOM GmbH](http://www.telcat.com) is a Germany-wide system house for innovative solutions and
services in the areas of information, communication and security technology.

We develop IP-based telecommunication systems ([TELCAT-UC](http://www.telcat.de/TELCAT-R-UC.304.0.html)) and
use Vagrant and Proxmox to automatically deploy and test the builds in our Jenkins jobs.
