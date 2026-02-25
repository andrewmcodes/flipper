RSpec.describe Flipper::UI::Actions::BooleanGate do
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

  describe 'POST /features/:feature/boolean' do
    context 'with enable' do
      before do
        flipper.disable :search
        post 'features/search/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper.enabled?(:search)).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context "with space in feature name" do
      before do
        flipper.disable :search
        post 'features/sp%20ace/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'updates feature' do
        expect(flipper.enabled?("sp ace")).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/sp+ace')
      end
    end

    context 'with disable' do
      before do
        flipper.enable :search
        post 'features/search/boolean',
             { 'action' => 'Disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'disables the feature' do
        expect(flipper.enabled?(:search)).to be(false)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'when fully_enable_disabled is true' do
      around do |example|
        begin
          @original_fully_enable_disabled = Flipper::UI.configuration.fully_enable_disabled
          Flipper::UI.configuration.fully_enable_disabled = true
          example.run
        ensure
          Flipper::UI.configuration.fully_enable_disabled = @original_fully_enable_disabled
        end
      end

      context 'with enable' do
        before do
          flipper.disable :search
          post 'features/search/boolean',
               { 'action' => 'Enable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'does not enable the feature' do
          expect(flipper.enabled?(:search)).to be(false)
        end

        it 'returns 403 status' do
          expect(last_response.status).to be(403)
        end

        it 'renders fully enable disabled template' do
          expect(last_response.body).to include('Fully enabling features from the UI is disabled')
        end
      end

      context 'with disable' do
        before do
          flipper.enable :search
          post 'features/search/boolean',
               { 'action' => 'Disable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'still allows disabling the feature' do
          expect(flipper.enabled?(:search)).to be(false)
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/search')
        end
      end
    end
  end
end
