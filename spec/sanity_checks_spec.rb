require 'spec_helper'

describe 'Vagrant Proxmox sanity checks' do

	describe 'when loaded without vagrant installed' do
		before { allow_any_instance_of(Object).to receive(:require) { raise LoadError } }
		it 'should raise an error' do
			expect { load 'sanity_checks.rb' }.to raise_error
		end
	end

	describe 'when used with an outdated vagrant version' do
		before { stub_const 'Vagrant::VERSION', '1.0.7' }
		it 'should raise an error' do
			expect { load 'sanity_checks.rb' }.to raise_error
		end
	end

end
