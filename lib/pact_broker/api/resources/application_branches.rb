require "pact_broker/api/resources/base_resource"
require "pact_broker/api/resources/pagination_methods"
require "pact_broker/api/resources/filter_methods"
require "pact_broker/api/resources/after_reply"
require "rack/utils"

module PactBroker
  module Api
    module Resources
      class ApplicationBranches < BaseResource
        include PaginationMethods
        include FilterMethods
        include AfterReply

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!application
        end

        def to_json
          decorator_class(:application_branches_decorator).new(branches).to_json(**decorator_options(application: application))
        end

        def policy_name
          :'versions::branches'
        end

        # Allows bulk deletion of application branches, keeping the specified branches and the main branch.
        # Deletes the branches asyncronously, after the response has been sent, for performance reasons.
        def delete_resource
          after_reply do
            branch_service.delete_branches_for_application(application, exclude: exclude)
          end
          notices = branch_service.branch_deletion_notices(application, exclude: exclude)
          response.body = decorator_class(:notices_decorator).new(notices).to_json(**decorator_options)
          202
        end

        private

        def branches
          @branches ||= branch_service.find_all_branches_for_application(
                          application,
                          filter_options,
                          default_pagination_options.merge(pagination_options),
                          eager_load_associations
                        )
        end

        def exclude
          Rack::Utils.parse_nested_query(request.uri.query)["exclude"] || []
        end

        def eager_load_associations
          decorator_class(:application_branches_decorator).eager_load_associations
        end
      end
    end
  end
end
