require "pact_broker/repositories"
require "pact_broker/logging"
require "pact_broker/messages"
require "pact_broker/applications/find_potential_duplicate_application_names"

module PactBroker
  module Applications
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      extend PactBroker::Messages

      def self.messages_for_potential_duplicate_applications(application_names, base_url)
        messages = []
        application_names.each do | name |
          potential_duplicate_applications = find_potential_duplicate_applications(name)
          if potential_duplicate_applications.any?
            messages << potential_duplicate_application_message(name, potential_duplicate_applications, base_url)
          end
        end
        messages
      end

      def self.find_potential_duplicate_applications application_name
        PactBroker::Applications::FindPotentialDuplicateApplicationNames
          .call(application_name, application_names).tap { | names|
            if names.any?
              logger.info "The following potential duplicate applications were found for #{application_name}: #{names.join(", ")}"
            end
          } .collect{ | name | application_repository.find_by_name(name) }
      end

      def self.find_all_applications(filter_options = {}, pagination_options = {}, eager_load_associations = [])
        application_repository.find_all(filter_options, pagination_options, eager_load_associations)
      end

      def self.find_application_by_name(name)
        application_repository.find_by_name(name)
      end

      # Used by pf
      # @param [Array<String>]
      # @return [Array<PactBroker::Domain::Application>]
      def self.find_applications_by_names(names)
        application_repository.find_by_names(names)
      end

      def self.find_application_by_name!(name)
        application_repository.find_by_name!(name)
      end

      def self.find_by_id(id)
        application_repository.find_by_id(id)
      end

      def self.find(options, pagination_options = {})
        application_repository.find(options, pagination_options)
      end

      def self.find_application_repository_url_by_application_name(name)
        application = application_repository.find_by_name(name)
        if application && application.repository_url
          application.repository_url
        else
          nil
        end
      end

      def self.update(application_name, application)
        application_repository.update(application_name, application)
      end

      def self.create(params)
        application_repository.create(params)
      end

      def self.replace(application_name, open_struct_application)
        application_repository.replace(application_name, open_struct_application)
      end

      def self.delete(name)
        application = find_application_by_name name
        webhook_service.delete_all_webhhook_related_objects_by_application(application)
        application_repository.delete(application)
      end

      def self.delete_if_orphan(application)
        application_repository.delete_if_orphan(application)
      end

      def self.application_names
        application_repository.application_names
      end

      def self.maybe_set_main_branch(application, potential_main_branch)
        if application.main_branch.nil? && PactBroker.configuration.auto_detect_main_branch && PactBroker.configuration.main_branch_candidates.include?(potential_main_branch)
          logger.info "Setting #{application.name} main_branch to '#{potential_main_branch}' (because the #{application.name} main_branch was nil and auto_detect_main_branch=true)"
          application_repository.set_main_branch(application, potential_main_branch)
        else
          application
        end
      end

      private_class_method def self.potential_duplicate_application_message(new_name, potential_duplicate_applications, base_url)
        existing_names = potential_duplicate_applications.
          collect{ | p | "* #{p.name}"  }.join("\n")
        message("errors.duplicate_application",
          new_name: new_name,
          existing_names: existing_names,
          base_url: base_url)
      end
    end
  end
end
