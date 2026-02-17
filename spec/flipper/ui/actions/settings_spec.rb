RSpec.describe Flipper::UI::Actions::Settings do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end

  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  describe 'GET /settings' do
    before do
      get '/settings'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('Download')
    end

    it 'includes migrate to Flipper Cloud card' do
      expect(last_response.body).to include('Migrate to Flipper Cloud')
    end

    it 'shows feature count' do
      expect(last_response.body).to include('features ready to migrate')
    end
  end
end
