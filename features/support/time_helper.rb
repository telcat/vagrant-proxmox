require_relative '../../spec/spec_helpers/time_helpers.rb'

Before '@timecop' do
	Timecop.freeze
	allow_any_instance_of(VagrantPlugins::Proxmox::Action::ProxmoxAction).to(receive(:sleep)) { |_, duration| Timecop.travel(Time.now + duration) }
end

After '@timecop' do
	Timecop.return
end
