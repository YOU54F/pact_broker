require "pact_broker/webmachine"
require "pact_broker/db/models"
require "pact_broker/api/resources"
require "pact_broker/api/decorators"
require "pact_broker/api/contracts"
require "pact_broker/application_context"
require "pact_broker/feature_toggle"

module Webmachine
  class Request
    def patch?
      method == "PATCH"
    end

    # This makes PATCH go through the PUT state machine path
    def put?
      method == "PUT" || method == "PATCH"
    end

    def really_put?
      method == "PUT"
    end
  end
end

module PactBroker
  # rubocop: disable Metrics/MethodLength
  def self.build_api(application_context = PactBroker::ApplicationContext.default_application_context)
    Webmachine.build_rack_api(application_context) do |app|
      app.routes do
        add(["trace", :*], Webmachine::Trace::TraceResource) unless ENV["RACK_ENV"] == "production"

        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "versions"], Api::Resources::PactVersions, {resource_name: "pact_publications"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "versions", :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publication", deprecated: true} # Not the standard URL, but keep for backwards compatibility
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "tag", :tag], Api::Resources::TaggedPactVersions, {resource_name: "tagged_pact_publications"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "branch", :branch_name], Api::Resources::PactVersionsForBranch, {resource_name: "pact_publications_for_branch"}

        # Pacts
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha], Api::Resources::PactVersion, {resource_name: "pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "metadata", :metadata], Api::Resources::PactVersion, {resource_name: "pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number, "previous-distinct"], Api::Resources::PreviousDistinctPactVersion, {resource_name: "previous_distinct_pact_version"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number, "diff", "previous-distinct"], Api::Resources::PactContentDiff, {resource_name: "previous_distinct_pact_version_diff"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number, "diff", "version", :comparison_consumer_version], Api::Resources::PactContentDiff, {resource_name: "pact_version_diff_by_consumer_version"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "diff", "pact-version", :comparison_pact_version_sha], Api::Resources::PactContentDiff, {resource_name: "pact_version_diff_by_pact_version_sha"}

        # Provider states

        add ["pacts", "provider", :provider_name, "provider-states"], Api::Resources::ProviderStates, { resource_name: "provider_states" }
        add ["pacts", "provider", :provider_name, "provider-states","branch", :branch_name], Api::Resources::ProviderStates, { resource_name: "provider_states_for_branch" }
        add ["pacts", "provider", :provider_name, "provider-states","environment", :environment_uuid], Api::Resources::ProviderStates, { resource_name: "provider_states_for_environment" }


        # Verifications
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "verification-results"], Api::Resources::Verifications, {resource_name: "verification_results"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "metadata", :metadata, "verification-results"], Api::Resources::Verifications, {resource_name: "verification_results"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number, "verification-results", "latest"], Api::Resources::LatestVerificationForPact, {resource_name: "latest_verification_results_for_pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "verification-results", "latest"], Api::Resources::LatestVerificationForPact, {resource_name: "latest_verification_results_for_pact_version"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "verification-results", :verification_number], Api::Resources::Verification, {resource_name: "verification_result"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "metadata", :metadata, "verification-results", :verification_number], Api::Resources::Verification, {resource_name: "verification_result"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "pact-version", :pact_version_sha, "verification-results", :verification_number, "triggered-webhooks"], Api::Resources::VerificationTriggeredWebhooks, {resource_name: "verification_result_triggered_webhooks"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest", "verification-results","latest"], Api::Resources::LatestVerificationForLatestPact, {resource_name: "latest_verification_results_for_latest_pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest", :tag, "verification-results","latest"], Api::Resources::LatestVerificationForLatestPact, {resource_name: "latest_verification_results_for_latest_tagged_pact_publication"}
        add ["verification-results", "consumer", :consumer_name, "version", :consumer_version_number,"latest"], Api::Resources::LatestVerificationsForConsumerVersion, {resource_name: "verification_results_for_consumer_version"}

        # Badges
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest", "badge"], Api::Resources::Badge, {resource_name: "latest_pact_badge"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest", :tag, "badge"], Api::Resources::Badge, {resource_name: "latest_tagged_pact_badge"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest-untagged", "badge"], Api::Resources::Badge, {resource_name: "latest_untagged_pact_badge", tag: :untagged}

        # Latest pacts
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest"], Api::Resources::LatestPact, {resource_name: "latest_pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest", :tag], Api::Resources::LatestPact, {resource_name: "latest_tagged_pact_publication"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "branch", :branch_name, "latest"], Api::Resources::LatestPact, {resource_name: "latest_pact_publication_for_branch"}
        add ["pacts", "provider", :provider_name], Api::Resources::ProviderPacts, {resource_name: "provider_pact_publications"}
        add ["pacts", "provider", :provider_name, "tag", :tag], Api::Resources::ProviderPacts, {resource_name: "tagged_provider_pact_publications"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "latest-untagged"], Api::Resources::LatestPact, {resource_name: "latest_untagged_pact_publication", tag: :untagged}
        add ["pacts", "provider", :provider_name, "latest"], Api::Resources::LatestProviderPacts, {resource_name: "latest_provider_pact_publications"}
        add ["pacts", "provider", :provider_name, "latest", :tag], Api::Resources::LatestProviderPacts, {resource_name: "latest_tagged_provider_pact_publications"}
        add ["pacts", "latest"], Api::Resources::LatestPacts, {resource_name: "latest_pacts"}

        # Pacts for verification
        add ["pacts", "provider", :provider_name, "for-verification"], Api::Resources::ProviderPactsForVerification, {resource_name: "pacts_for_verification"}

        # Deprecated pact
        add ["pact", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number], Api::Resources::Pact, {resource_name: "pact_publication", deprecated: "true"} # Deprecate, singular /pact
        add ["pact", "provider", :provider_name, "consumer", :consumer_name, "latest"], Api::Resources::LatestPact, {resource_name: "latest_pact_publications", deprecated: "true"}

        # Applications
        add ["applications"], Api::Resources::Applications, {resource_name: "applications"}
        add ["applications", "label", :label_name], PactBroker::Api::Resources::ApplicationsForLabel, {resource_name: "applications_for_label"}
        add ["applications", :application_name], Api::Resources::Application, {resource_name: "application"}
        add ["applications", :application_name, "labels", :label_name], Api::Resources::Label, {resource_name: "application_label"}
        # Labels
        add ["labels"], Api::Resources::Labels, {resource_name: "labels"}

        # Versions
        add ["applications", :application_name, "versions"], Api::Resources::Versions, {resource_name: "application_versions"}
        add ["applications", :application_name, "branches", :branch_name, "versions"], Api::Resources::BranchVersions, {resource_name: "application_branch_versions"}
        add ["applications", :application_name, "versions", :application_version_number], Api::Resources::Version, {resource_name: "application_version"}
        add ["applications", :application_name, "latest-version", :tag], Api::Resources::LatestVersion, {resource_name: "latest_tagged_application_version"}
        add ["applications", :application_name, "latest-version", :tag, "can-i-deploy", "to", :to], Api::Resources::CanIDeployApplicationVersionByTagToTag, { resource_name: "can_i_deploy_latest_tagged_version_to_tag" }
        add ["applications", :application_name, "latest-version", :tag, "can-i-deploy", "to", :to, "badge"], Api::Resources::CanIDeployApplicationVersionByTagToTagBadge, { resource_name: "can_i_deploy_latest_tagged_version_to_tag_badge" }
        add ["applications", :application_name, "main-branch", "can-i-merge", "badge"], Api::Resources::CanIMergeBadge, { resource_name: "can_i_merge_badge" }
        add ["applications", :application_name, "latest-version"], Api::Resources::LatestVersion, {resource_name: "latest_application_version"}
        add ["applications", :application_name, "versions", :application_version_number, "tags", :tag_name], Api::Resources::Tag, {resource_name: "application_version_tag"}
        add ["applications", :application_name, "branches"], Api::Resources::ApplicationBranches, {resource_name: "application_branches"}
        add ["applications", :application_name, "branches", :branch_name], Api::Resources::Branch, { resource_name: "branch" }
        add ["applications", :application_name, "branches", :branch_name, "latest-version"], Api::Resources::LatestVersion, { resource_name: "latest_application_version_for_branch" }
        add ["applications", :application_name, "branches", :branch_name, "versions", :version_number], Api::Resources::BranchVersion, { resource_name: "branch_version" }
        add ["applications", :application_name, "branches", :branch_name, "latest-version", "can-i-deploy", "to-environment", :environment_name], Api::Resources::CanIDeployApplicationVersionByBranchToEnvironment, { resource_name: "can_i_deploy_latest_branch_version_to_environment" }
        add ["applications", :application_name, "branches", :branch_name, "latest-version", "can-i-deploy", "to-environment", :environment_name, "badge"], Api::Resources::CanIDeployApplicationVersionByBranchToEnvironmentBadge, { resource_name: "can_i_deploy_latest_branch_version_to_environment_badge" }

        # Webhooks
        add ["webhooks", "provider", :provider_name, "consumer", :consumer_name ], Api::Resources::ApplicationWebhooks, {resource_name: "application_webhooks"}
        add ["webhooks", "provider", :provider_name], Api::Resources::ApplicationWebhooks, {resource_name: "provider_webhooks"}
        add ["webhooks", "consumer", :consumer_name], Api::Resources::ApplicationWebhooks, {resource_name: "consumer_webhooks"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "webhooks"], Api::Resources::PactWebhooks, {resource_name: "pact_webhooks"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "webhooks", "status"], Api::Resources::PactWebhooksStatus, {resource_name: "pact_webhooks_status"}
        add ["pacts", "provider", :provider_name, "consumer", :consumer_name, "version", :consumer_version_number, "triggered-webhooks"], Api::Resources::PactTriggeredWebhooks, {resource_name: "pact_triggered_webhooks"}

        add ["webhooks", "execute" ], Api::Resources::WebhookExecution, {resource_name: "execute_unsaved_webhook"}
        add ["webhooks", :uuid ], Api::Resources::Webhook, {resource_name: "webhook"}
        add ["triggered-webhooks", :uuid, "logs" ], Api::Resources::TriggeredWebhookLogs, { resource_name: "triggered_webhook_logs" }
        add ["webhooks", :uuid, "execute" ], Api::Resources::WebhookExecution, {resource_name: "execute_webhook"}
        add ["webhooks"], Api::Resources::AllWebhooks, {resource_name: "webhooks"}

        add ["relationships"], Api::Resources::Relationships, {resource_name: "relationships"}
        add ["groups", :application_name], Api::Resources::Group, {resource_name: "group"}

        # matrix
        add ["matrix", "provider", :provider_name, "consumer", :consumer_name], Api::Resources::MatrixForConsumerAndProvider, {resource_name: "matrix_consumer_provider"}
        add ["matrix", "provider", :provider_name, "latest", :provider_tag, "consumer", :consumer_name, "latest", :tag, "badge"], Api::Resources::MatrixBadge, {resource_name: "matrix_tag_badge"}
        add ["matrix"], Api::Resources::Matrix, {resource_name: "matrix"}
        add ["can-i-deploy"], Api::Resources::CanIDeploy, {resource_name: "can_i_deploy"}

        add ["dashboard"], Api::Resources::Dashboard, {resource_name: "dashboard"}
        add ["dashboard", "provider", :provider_name, "consumer", :consumer_name ], Api::Resources::Dashboard, {resource_name: "integration_dashboard"}
        add ["test","error"], Api::Resources::ErrorTest, {resource_name: "error_test"}

        add ["contracts", "publish"], Api::Resources::PublishContracts, { resource_name: "publish_contracts" }

        add ["environments"], Api::Resources::Environments, { resource_name: "environments" }
        add ["environments", :environment_uuid], Api::Resources::Environment, { resource_name: "environment" }
        add ["environments", :environment_uuid, "deployed-versions", "currently-deployed"], Api::Resources::CurrentlyDeployedVersionsForEnvironment, { resource_name: "environment_currently_deployed_deployed_versions" }
        add ["environments", :environment_uuid, "released-versions", "currently-supported"], Api::Resources::CurrentlySupportedVersionsForEnvironment, { resource_name: "environment_currently_supported_released_versions" }
        add ["applications", :application_name, "versions", :application_version_number, "deployed-versions", "environment", :environment_uuid], Api::Resources::DeployedVersionsForVersionAndEnvironment, { resource_name: "deployed_versions_for_version_and_environment" }
        add ["applications", :application_name, "versions", :application_version_number, "released-versions", "environment", :environment_uuid], Api::Resources::ReleasedVersionsForVersionAndEnvironment, { resource_name: "released_versions_for_version_and_environment" }
        add ["released-versions", :uuid], Api::Resources::ReleasedVersion, { resource_name: "released_version" }
        add ["deployed-versions", :uuid], Api::Resources::DeployedVersion, { resource_name: "deployed_version" }

        add ["integrations"], Api::Resources::Integrations, {resource_name: "integrations"}
        add ["integrations", "provider", :provider_name, "consumer", :consumer_name], Api::Resources::Integration, {resource_name: "integration"}
        add ["metrics"], Api::Resources::Metrics, {resource_name: "metrics"}
        add [], Api::Resources::Index, {resource_name: "index"}

        add ["applications", :application_name, "tags", :tag_name, "versions"], Api::Resources::TagVersions, {resource_name: "application_tag_versions"}

      end
    end
  end


  API ||= begin
    build_api
  end

  def self.routes
    require "webmachine/describe_routes"
    @routes ||= Webmachine::DescribeRoutes.call([API.application])
  end
  # rubocop: enable Metrics/MethodLength
end
