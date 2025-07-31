require "pact_broker/api/resources/can_i_deploy_application_version_by_tag_to_tag"
require "pact_broker/api/resources/badge_methods"

module PactBroker
  module Api
    module Resources
      class CanIDeployApplicationVersionByTagToTagBadge < CanIDeployApplicationVersionByTagToTag
        include BadgeMethods

        def badge_url
          if application
            if version
              badge_service.can_i_deploy_badge_url(identifier_from_path[:tag], identifier_from_path[:to], label, results.deployable?)
            else
              badge_service.error_badge_url("version", "not found")
            end
          else
            badge_service.error_badge_url("application", "not found")
          end
        end
      end
    end
  end
end
