require "pact_broker/api/resources/base_resource"
require "pact_broker/api/contracts/application_schema"

module PactBroker
  module Api
    module Resources
      class Application < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [
            ["application/json", :from_json],
            ["application/merge-patch+json", :from_merge_patch_json]
          ]
        end

        def allowed_methods
          ["GET", "PUT", "PATCH", "DELETE", "OPTIONS"]
        end

        def put_can_create?
          false
        end

        def patch_can_create?
          true
        end

        def known_methods
          super + ["PATCH"]
        end

        def malformed_request?
          super || ((request.patch? || request.really_put?) && any_request_body? && validation_errors_for_schema?)
        end

        # PUT or PATCH with content-type application/json
        def from_json
          if application
            @application = update_existing_application
          else
            if request.patch? # for backwards compatibility, wish I hadn't done this
              @application = create_new_application
              response.headers["Location"] = application_url(base_url, application)
            else
              return 404
            end
          end
          response.body = to_json
        end

        # PUT or PATCH with content-type application/merge-patch+json
        def from_merge_patch_json
          if request.patch?
            from_json
          else
            415
          end
        end

        def resource_exists?
          !!application
        end

        def delete_resource
          application_service.delete(application_name)
          true
        end

        def to_json
          decorator_class(:application_decorator).new(application)
            .to_json(**decorator_options(deployed_versions: deployed_versions))
        end

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_all_deployed_versions_for_application(application)
        end

        def parsed_application(application)
          decorator_class(:application_decorator).new(application).from_json(request_body)
        end

        def policy_name
          :'applications::application'
        end

        def schema
          PactBroker::Api::Contracts::ApplicationSchema
        end

        def update_existing_application
          if request.really_put?
            @application = application_service.replace(application_name, parsed_application(OpenStruct.new))
          else
            @application = application_service.update(application_name, parsed_application(application))
          end
        end

        def create_new_application
          application_service.create parsed_application(OpenStruct.new).to_h.merge(:name => application_name)
        end
      end
    end
  end
end
