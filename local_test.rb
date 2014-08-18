require 'yaml'
$:<<"./lib/"
require 'rest-client'
require 'vagrant-proxmox/proxmox/connection'
require 'json'
require 'vagrant-proxmox'
require_relative 'features/support/vagrant_ui_mock.rb'

@conn=VagrantPlugins::Proxmox::Connection.new 'https://proxmox1.telcatdo.telcat.de:8006/api2/json'
config=YAML.load_file("#{ENV['HOME']}/.rake/rake.yml")
@conn.login username: config['proxmox']['user_name'] , password: config['proxmox']['password']

@environment = Vagrant::Environment.new vagrantfile_name: 'Vagrantfile'
@ui = VagrantUIMock.new
@environment.instance_variable_set :@ui, @ui

# Vagrant.plugin('2').manager.commands[:up].new(['--provider=proxmox'], @environment).execute