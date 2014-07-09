shared_examples 'a proxmox action call' do

	describe 'when done' do
		it 'should call the next action' do
			expect(subject).to receive(:next_action).with env
			subject.call env
		end
	end

end
