require "json"
require "flipper/adapters/http/client"

module Flipper
  module Cloud
    MigrateResult = Struct.new(:code, :url, :message, keyword_init: true)

    DEFAULT_CLOUD_URL = "https://www.flippercloud.io".freeze

    # Public: Migrate features to Flipper Cloud.
    #
    # flipper  - The Flipper instance to export features from (default: Flipper).
    # app_name - Optional String name of the application.
    #
    # Returns a MigrateResult with code, url, and message.
    def self.migrate(flipper = Flipper, app_name: nil)
      export = flipper.export(format: :json, version: 1)
      payload = {
        export: JSON.parse(export.contents),
        metadata: {app_name: app_name},
      }

      client = build_client("/api")
      response = client.post("/migrate", JSON.generate(payload))
      body = JSON.parse(response.body) rescue {}

      MigrateResult.new(
        code: response.code.to_i,
        url: body["url"],
        message: body["error"],
      )
    end

    # Public: Push features to an existing Flipper Cloud project.
    #
    # token   - The String token for the Cloud environment.
    # flipper - The Flipper instance to export features from (default: Flipper).
    #
    # Returns a MigrateResult with code and message.
    def self.push(token, flipper = Flipper)
      export = flipper.export(format: :json, version: 1)

      client = build_client("/adapter", headers: {
        "flipper-cloud-token" => token,
      })
      response = client.post("/import", export.contents)
      body = JSON.parse(response.body) rescue {}

      MigrateResult.new(
        code: response.code.to_i,
        url: nil,
        message: body["error"],
      )
    end

    # Private: Build an HTTP client for Cloud API requests.
    def self.build_client(path, headers: {})
      base_url = ENV.fetch("FLIPPER_CLOUD_URL", DEFAULT_CLOUD_URL)

      Flipper::Adapters::Http::Client.new(
        url: "#{base_url}#{path}",
        headers: headers,
        open_timeout: 5,
        read_timeout: 30,
        write_timeout: 30,
        max_retries: 2,
      )
    end
    private_class_method :build_client
  end
end
