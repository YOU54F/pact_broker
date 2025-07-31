require "pact_broker/api/resources/can_i_deploy_application_version_by_branch_to_environment"

module PactBroker
  module Api
    module Resources
      class CanIDeployApplicationVersionByBranchToEnvironmentBadge < CanIDeployApplicationVersionByBranchToEnvironment
        include BadgeMethods

        private

        def badge_url
          if application && version && environment
            badge_service.can_i_deploy_badge_url(identifier_from_path[:branch_name], identifier_from_path[:environment_name], label, results.deployable?)
          elsif application.nil?
            badge_service.error_badge_url("application", "not found")
          elsif version.nil?
            if branch_service.find_branch(**identifier_from_path.slice(:application_name, :branch_name)).nil?
              badge_service.error_badge_url("branch", "not found")
            else
              badge_service.error_badge_url("version", "not found")
            end
          else
            badge_service.error_badge_url("environment", "not found")
          end
        end
      end
    end
  end
end
