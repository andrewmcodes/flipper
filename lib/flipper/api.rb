require 'rack'
require 'flipper'
require 'flipper/api/middleware'
require 'flipper/api/json_params'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'.freeze

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      use_rewindable_middleware = options.fetch(:use_rewindable_middleware) {
        Gem::Version.new(Rack.release) >= Gem::Version.new('3.0.0')
      }
      app = ->(_) { [404, { Rack::CONTENT_TYPE => CONTENT_TYPE }, ['{}'.freeze]] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Rack::Head
      builder.use Rack::Deflater
      builder.use Rack::RewindableInput::Middleware if use_rewindable_middleware
      builder.use Flipper::Api::JsonParams
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Api::Middleware, env_key: env_key
      builder.run app
      klass = self
      app = builder.to_app
      app.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      app
    end
  end
end
