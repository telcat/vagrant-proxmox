module VagrantPlugins::Proxmox

	shared_examples 'a rest api call' do |rest_method|

		context 'when an invalid resource is requested' do
			before { allow(RestClient).to receive(rest_method).and_raise RestClient::NotImplemented }
			it 'should raise a connection error' do
				expect do
					connection.send rest_method, '/invalid_resource'
				end.to raise_error ApiError::NotImplemented
			end
		end

		context 'when an internal server error occurs' do
			before { allow(RestClient).to receive(rest_method).and_raise RestClient::InternalServerError }
			it 'should raise a server error' do
				expect do
					connection.send rest_method, '/invalid_resource'
				end.to raise_error ApiError::ServerError
			end
		end

		context 'when a network error occurs' do
			before { allow(RestClient).to receive(rest_method).and_raise SocketError }
			it 'should raise a connection error' do
				expect do
					connection.send rest_method, '/resource'
				end.to raise_error ApiError::ConnectionError
			end
		end

		context 'when the client is not authorized' do
			before { allow(RestClient).to receive(rest_method).and_raise RestClient::Unauthorized }
			it 'should raise a unauthorized error' do
				expect do
					connection.send rest_method, "/resource"
				end.to raise_error ApiError::UnauthorizedError
			end
		end
	end
end