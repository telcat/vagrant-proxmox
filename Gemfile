source 'https://rubygems.org'

gemspec

group :development do
	#We depend on Vagrant for development, but we don't add it as a
	#gem dependency because we expect to be installed within the
	#Vagrant environment itself using `vagrant plugin`.
	gem "vagrant", '1.4.3',
	    # :git => 'https://github.com/mitchellh/vagrant.git',
			:git => 'https://github.com/telcat/vagrant.git',
	    :ref => 'v1.4.3.r1'
end
