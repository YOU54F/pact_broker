module PactBroker
  module Api
    module Resources
      module ApplicationResourceMethods

        def potential_duplicate_applications? application_names
          if PactBroker.configuration.check_for_potential_duplicate_application_names
            messages = application_service.messages_for_potential_duplicate_applications application_names, base_url
            if messages.any?
              response.body = messages.join("\n")
              response.headers["content-type"] = "text/plain"
            end
            messages.any?
          else
            false
          end
        end
      end
    end
  end
end
