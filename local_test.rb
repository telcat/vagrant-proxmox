require 'yaml'
$:<<"./lib/"
require 'rest-client'
require 'vagrant-proxmox/proxmox/connection'
require 'json'
require 'vagrant-proxmox'
require_relative 'features/support/vagrant_ui_mock.rb'


config=YAML.load_file("#{ENV['HOME']}/.rake/rake.yml")
@conn=VagrantPlugins::Proxmox::Connection.new config['proxmox']['endpoint']
@conn.login username: config['proxmox']['user_name'] , password: config['proxmox']['password']

@environment = Vagrant::Environment.new vagrantfile_name: 'Vagrantfile_qemu'
@ui = VagrantUIMock.new
@environment.instance_variable_set :@ui, @ui

# Vagrant.plugin('2').manager.commands[:up].new(['--provider=proxmox'], @environment).execute