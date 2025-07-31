require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/applications_decorator"

module PactBroker
  module Api
    module Resources
      class ApplicationsForLabel < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          generate_json(application_service.find identifier_from_path )
        end

        def generate_json applications
          decorator_class(:applications_decorator).new(applications).to_json(**decorator_options)
        end

        def policy_name
          :'applications::applications'
        end
      end
    end
  end
end
