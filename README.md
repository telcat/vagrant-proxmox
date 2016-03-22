# Vagrant Proxmox Provider

This is a [Vagrant](http://www.vagrantup.com) plugin that adds a
[Proxmox](http://proxmox.com/) provider to Vagrant, allowing Vagrant to manage
and provision Proxmox virtual machines.

## Features

* Create/Destroy OpenVZ containers from specified templates
* Start/Shutdown OpenVZ containers
* Create/Destroy Qemu containers from specified templates or iso file
* Start/Shutdown Qemu containers
* SSH into virtual machine
* Provision the virtual machine
* Synced folder support via rsync

## Limitations

* For OpenVZ containers you need a Vagrant compatible OpenVZ template
* For OpenVZ containers only routed network mode is currently supported
* For KVM machines the ISO file needs to be a Vagrant compatible live system or automatic installation
* For KVM machines the Qemu template has to be on the selected_node

## Requirements

* Vagrant 1.5+
* Ruby 2+

## Installation

Install using standard Vagrant plugin method:

```
$ vagrant plugin install vagrant-proxmox
```

This will install the plugin from [RubGems.org](http://rubygems.org/).

## Usage

First install the provided dummy vagrant box:

```
$ vagrant box add dummy dummy_box/dummy.box
```

Then for an openvz container create a Vagrantfile that looks like the following (note that you might have to add "@pam" to your username if you're getting a "401 Unauthorized" error):

```
Vagrant.configure('2') do |config|

    config.vm.provider :proxmox do |proxmox|
        proxmox.endpoint = 'https://your.proxmox.server:8006/api2/json'
        proxmox.user_name = 'proxmox_username@pam'
        proxmox.password = 'proxmox_password'
        proxmox.vm_id_range = 900..910
        proxmox.vm_name_prefix = 'vagrant_'
        proxmox.openvz_os_template = 'local:vztmpl/vagrant-proxmox-ubuntu-12.tar.gz'
        proxmox.vm_type = :openvz
        proxmox.vm_memory = 256
    end
    
    config.vm.define :box, primary: true do |box|
        box.vm.box = 'dummy'
        box.vm.network :public_network, ip: '192.168.0.1'
    end
    
end
```

If you want KVM the Vagrantfile could look as follows:

```
Vagrant.configure('2') do |config|

    config.vm.provider :proxmox do |proxmox|
        proxmox.endpoint = 'https://proxmox.example.com/api2/json'
        proxmox.user_name = 'vagrant'
        proxmox.password = 'password'
        proxmox.vm_id_range = 900..910
        proxmox.vm_type = :qemu
        proxmox.vm_name_prefix = 'vagrant_'
        proxmox.qemu_os = :l26
        proxmox.qemu_disk_size = '30G'
        proxmox.qemu_storage = 'local'
        proxmox.qemu_iso_file = '/home/user/system.iso'
        proxmox.vm_name_prefix = 'vagrant_test_'
        proxmox.qemu_cores = 1
        proxmox.qemu_sockets = 1
        proxmox.qemu_nic_model = 'virtio'
        proxmox.qemu_bridge = 'vmbr0'
        proxmox.vm_memory = 512
    end

    config.vm.define :box, primary: true do |box|
        box.vm.box = 'dummy'
        box.vm.network :public_network, ip: '192.168.0.1', macaddress: 'ff:aa:cc:dd:bb:ee'
    end

end
```

For the meaning of the various options, refer to the `Options` section below.

You need an OpenVZ template or KVM ISO that contains a vagrant user supplied with the default Vagrant SSH keys.
You can download an example Ubuntu based template [here](https://www.dropbox.com/s/vuzywdosxhjjsag/vagrant-proxmox-ubuntu-12.tar.gz).

Finally run `vagrant up --provider=proxmox` to create and start the new OpenVZ container.

## Options

* `endpoint` URL of the JSON API endpoint of your Proxmox installation
* `user_name` The name of the Proxmox user that Vagrant should use
* `password` The password of the above user
* `vm_id_range` The possible range of machine ids. The smallest free one is chosen for a new machine
* `vm_name_prefix` An optional string that is prepended before the vm name
* `vm_type` The virtual machine type, e.g. :openvz or :qemu
* `openvz_os_template` The name of the template from which the OpenVZ container should be created
* `openvz_template_file` The openvz os template file to upload and use for the virtual machine (can be specified instead of `openvz_os_template`)
* `replace_openvz_template_file` Set to true if the openvz os template file should be replaced on the server (default: false)
* `vm_memory` The container's main memory size
* `task_timeout` How long to wait for completion of a Proxmox API command (in seconds)
* `task_status_check_interval` Interval in seconds between checking for completion of a Proxmox API command
* `ssh_timeout` The maximum timeout for a ssh connection to a virtual machine (in seconds)
* `ssh_status_check_interval` The interval between two ssh reachability status retrievals (in seconds)
* `imgcopy_timeout` The maximum timeout for a proxmox server task in case it's an upload (in seconds)
* `qemu_os` The qemu virtual machine operating system, e.g. :l26
* `qemu_iso` The qemu iso file to use for the virtual machine
* `qemu_iso_file` The qemu iso file to upload and use for the virtual machine (can be specified instead of `qemu_iso`)
* `replace_qemu_iso_file` Set to true if the iso file should be replaced on the server (default: false)
* `replace_template` Set to true if the iso file should be replaced on the server (default: false)
* `qemu_template` The name of a qemu template which is used to create a clone (can be specified instead of `qemu_iso[_file]`)
* `qemu_disk_size` The qemu disk size to use for the virtual machine, e.g. '30G'
* `qemu_storage` The storage pool to use, i.e. the value of the `storage` key of the hash returned by `pvesh get /nodes/{node}/storage`, e.g. 'raid', 'local', 'cephstore'
* `qemu_cores` The number of cores per socket available to the VM
* `qemu_sockets` The number of CPU sockets available to the VM
* `qemu_nic_model` which model of network interface card to use, default 'e1000'
* `qemu_bridge` connect automatically to this bridge, default 'vmbr0'
* `selected_node` If specified, only this specific node is used to create machines 

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
