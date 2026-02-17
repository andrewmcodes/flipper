require "net/http"
require "json"
require "uri"

module Flipper
  module Cloud
    MigrateResult = Struct.new(:code, :url, keyword_init: true)

    DEFAULT_CLOUD_URL = "https://www.flippercloud.io".freeze

    # Public: Migrate features to Flipper Cloud.
    #
    # flipper  - The Flipper instance to export features from (default: Flipper).
    # app_name - Optional String name of the application.
    #
    # Returns a MigrateResult with code and url.
    def self.migrate(flipper = Flipper, app_name: nil)
      export = flipper.export(format: :json, version: 1)
      payload = {
        export: JSON.parse(export.contents),
        metadata: {app_name: app_name},
      }

      base_url = ENV.fetch("FLIPPER_CLOUD_URL", DEFAULT_CLOUD_URL)
      uri = URI.parse("#{base_url}/api/migrate")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = JSON.generate(payload)

      response = http.request(request)
      body = JSON.parse(response.body) rescue {}

      MigrateResult.new(code: response.code.to_i, url: body["url"])
    end

    # Public: Push features to an existing Flipper Cloud project.
    #
    # token   - The String token for the Cloud environment.
    # flipper - The Flipper instance to export features from (default: Flipper).
    #
    # Returns a MigrateResult with code and url.
    def self.push(token, flipper = Flipper)
      export = flipper.export(format: :json, version: 1)

      base_url = ENV.fetch("FLIPPER_CLOUD_URL", DEFAULT_CLOUD_URL)
      uri = URI.parse("#{base_url}/adapter/import")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["Flipper-Cloud-Token"] = token
      request.body = export.contents

      response = http.request(request)

      MigrateResult.new(code: response.code.to_i, url: nil)
    end
  end
end
