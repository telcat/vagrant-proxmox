require 'vagrant/util/subprocess'

module VagrantPlugins
	module Proxmox
		module Action

			# This action uses 'rsync' to sync the folders over to the virtual machine.
			class SyncFolders < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::sync_folders'
				end

				def call env
					ssh_info = env[:machine].ssh_info

					env[:machine].config.vm.synced_folders.each do |_, data|
						hostpath = File.expand_path data[:hostpath], env[:root_path]
						guestpath = data[:guestpath]
						next if data[:disabled]

						# Make sure there is a trailing slash on the host path to
						# avoid creating an additional directory with rsync
						hostpath = "#{hostpath}/" if hostpath !~ /\/$/

						env[:ui].info I18n.t('vagrant_proxmox.rsync_folder', hostpath: hostpath, guestpath: guestpath)

						# Create the guest path
						env[:machine].communicate.sudo "mkdir -p '#{guestpath}'"
						env[:machine].communicate.sudo "chown #{ssh_info[:username]} '#{guestpath}'"

						# rsync over to the guest path using the SSH info
						command = [
								'rsync', '--verbose', '--archive', '--compress', '--delete',
								'-e', "ssh -p #{ssh_info[:port]} -i '#{ssh_info[:private_key_path][0]}' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null",
								hostpath, "#{ssh_info[:username]}@#{ssh_info[:host]}:#{guestpath}"]

						rsync_process = Vagrant::Util::Subprocess.execute *command
						if rsync_process.exit_code != 0
							raise Errors::RsyncError, guestpath: guestpath, hostpath: hostpath, stderr: rsync_process.stderr
						end
					end

					next_action env
				end

			end

		end
	end
end
