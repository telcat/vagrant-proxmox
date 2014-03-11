require 'rake'
require 'rake/clean'
require 'rubygems'
require 'bundler/setup'
require 'rubygems/gem_runner'
require 'rspec/core/rake_task'
require 'geminabox_client'

gemspec = eval(File.read 'vagrant-proxmox.gemspec')

desc 'Build the project'
task :build do
	Gem::GemRunner.new.run ['build', "#{gemspec.name}.gemspec"]
end

RSpec::Core::RakeTask.new

desc 'Run RSpec code examples with coverage'
RSpec::Core::RakeTask.new('spec_coverage') do |_|
	ENV['RUN_WITH_COVERAGE'] = 'true'
end

task release: [:build, :spec_coverage] do
	rake_config = YAML::load(File.read("#{ENV['HOME']}/.rake/rake.yml")) rescue {}
	GeminaboxClient.new(rake_config['geminabox']['url']).push "#{gemspec.name}-#{gemspec.version}.gem", overwrite: true
	puts "Gem #{gemspec.name} pushed to #{rake_config['geminabox']['url']}"
end
