require "pact_broker/repositories"
require "pact_broker/configuration"
require "pact_broker/logging"

module PactBroker
  module Tags
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def create args
        tag_name = args.fetch(:tag_name)
        application = application_repository.find_by_name_or_create args.fetch(:application_name)
        version = version_repository.find_by_application_id_and_number_or_create application.id, args.fetch(:application_version_number)
        version_service.maybe_set_version_branch_from_tag(version, tag_name)
        application_service.maybe_set_main_branch(version.application, tag_name)
        tag_repository.create(version: version, name: tag_name)
      end

      def find args
        tag_repository.find args
      end

      def delete args
        version = version_repository.find_by_application_name_and_number args.fetch(:application_name), args.fetch(:application_version_number)
        connection = PactBroker::Domain::Tag.new.db
        connection.run("delete from tags where name = '#{args.fetch(:tag_name)}' and version_id = '#{version.id}'")
      end

      def find_all_tag_names_for_application application_name
        tag_repository.find_all_tag_names_for_application application_name
      end

      def find_all_by_application_name_and_tag application_name:, tag_name:
        tag_repository.find_all_by_application_name_and_tag application_name, tag_name
      end
    end
  end
end
