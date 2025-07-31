require "pact_broker/deployments/deployed_version"
require "pact_broker/repositories/scopes"
require "pact_broker/events/publisher"

module PactBroker
  module Deployments
    class DeployedVersionService
      include PactBroker::Logging
      extend PactBroker::Repositories::Scopes
      extend PactBroker::Services
      extend PactBroker::Events::Publisher

      def self.next_uuid
        SecureRandom.uuid
      end

      # Policy applied at resource level to Version
      def self.find_by_uuid(uuid)
        DeployedVersion.where(uuid: uuid).single_record
      end

      def self.find_or_create(uuid, version, environment, target, auto_created: false)
        if (deployed_version = find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target))
          deployed_version
        else
          record_previous_version_undeployed(version.application, environment, target)
          deployed_version = DeployedVersion.create(
            uuid: uuid,
            version: version,
            application_id: version.application_id,
            environment: environment,
            target: target,
            auto_created: auto_created
          )
          broadcast(:deployed_version_created, { deployed_version: deployed_version })
          deployed_version
        end
      end

      def self.find_deployed_versions_for_version_and_environment(version, environment)
        scope_for(DeployedVersion)
          .for_version_and_environment(version, environment)
          .order_by_date_desc
          .all
      end

      def self.find_deployed_versions_for_version(version)
        scope_for(DeployedVersion)
          .where(version_id: version.id)
          .eager(:environment)
          .all
      end

      def self.find_deployed_versions_for_versions(versions_array)
        scope_for(DeployedVersion)
          .where(version_id: versions_array.map(&:id))
          .eager(:environment)
          .to_hash_groups(:version_id)
      end

      # Policy applied at resource level to Version
      def self.find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target)
        DeployedVersion
          .currently_deployed
          .for_version_and_environment_and_target(version, environment, target)
          .single_record
      end

      def self.find_all_deployed_versions_for_application(application)
        scope_for(DeployedVersion)
          .where(application_id: application.id)
          .eager(:environment)
          .all
      end

      def self.find_currently_deployed_versions_for_environment(environment, application_name: nil, target: :unspecified)
        query = scope_for(DeployedVersion)
          .currently_deployed
          .for_environment(environment)
          .order_by_date_desc

        query = query.for_application_name(application_name) if application_name
        query = query.for_target(target) if target != :unspecified
        query.all
      end

      def self.find_currently_deployed_versions_for_application(application)
        scope_for(DeployedVersion)
          .currently_deployed
          .where(application_id: application.id)
          .eager(:version)
          .eager(:environment)
          .order(:created_at, :id)
          .all
      end

      def self.record_version_undeployed(deployed_version)
        deployed_version.currently_deployed_version_id&.delete
        deployed_version.record_undeployed
      end

      def self.maybe_create_deployed_version_for_tag(version, environment_name)
        if PactBroker.configuration.create_deployed_versions_for_tags
          if (environment = environment_service.find_by_name(environment_name))
            logger.info("Creating deployed version for #{version.application.name} version #{version.number} in environment #{environment_name} (because create_deployed_versions_for_tags=true)")
            find_or_create(next_uuid, version, environment, nil, auto_created: true)
          end
        end
      end

      def self.record_previous_version_undeployed(application, environment, target)
        DeployedVersion.where(
          undeployed_at: nil,
          application_id: application.id,
          environment_id: environment.id,
          target: target
        ).record_undeployed
      end

      private_class_method :record_previous_version_undeployed
    end
  end
end
