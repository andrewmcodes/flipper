require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class CloudMigrate < UI::Action
        route %r{\A/settings\/cloud/?\Z}

        def post
          result = Flipper::Cloud.migrate(flipper)

          if result.url
            status 302
            header 'location', result.url
            halt [@code, @headers, ['']]
          else
            redirect_to "/settings?error=#{Flipper::UI::Util.escape("Migration failed (HTTP #{result.code})")}"
          end
        end
      end
    end
  end
end
