# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^lib/vagrant-proxmox/action/(.+)\.rb$})     { |m| "spec/actions/#{m[1]}_action_spec.rb" }
end

