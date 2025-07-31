require "pact_broker/string_refinements"
require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/relationships_csv_decorator"

module PactBroker
  module Api
    module Resources
      class Group < BaseResource
        using PactBroker::StringRefinements

        def content_types_provided
          [["text/csv", :to_csv]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          application
        end

        def to_csv
          if group
            decorator_class(:relationships_csv_decorator).new(group).to_csv
          else
            ""
          end
        end

        def policy_name
          :'groups::group'
        end

        private

        def group
          @group ||= group_service.find_group_containing(application, max_applications: max_applications)
        end

        def max_applications
          if request.query["maxApplications"]&.integer?
            request.query["maxApplications"].to_i
          end
        end
      end
    end
  end
end
