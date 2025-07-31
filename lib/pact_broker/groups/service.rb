require "pact_broker/repositories"
require "pact_broker/domain/index_item"

module PactBroker
  module Groups
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      # Returns a list of all the integrations (PactBroker::Domain::IndexItem) that are connected to the given application.
      # @param application [PactBroker::Domain::Application] the application for which to return the connected applications
      # @option max_applications [Integer] the maximum number of applications to return, or nil for no maximum. 40 is about the most applications you can meaningfully show in the circle network diagram.
      # @return [PactBroker::Domain::Group]
      def find_group_containing(application, max_applications: nil)
        PactBroker::Domain::Group.new(build_index_items(integrations_connected_to(application, max_applications)))
      end

      def integrations_connected_to(application, max_applications)
        PactBroker::Integrations::Integration
          .eager(:consumer, :provider)
          .where(id: ids_of_integrations_connected_to(application, max_applications))
          .all
      end
      private_class_method :integrations_connected_to

      def build_index_items(integrations)
        integrations.collect do | integration |
          PactBroker::Domain::IndexItem.new(integration.consumer, integration.provider)
        end
      end
      private_class_method :build_index_items

      def ids_of_integrations_connected_to(application, max_applications)
        integrations = []
        connected_applications = Set.new([application.id])
        new_connected_applications = Set.new([application.id])

        loop do
          new_integrations = PactBroker::Integrations::Integration.including_application_id(new_connected_applications.to_a).exclude(id: integrations.collect(&:id)).all
          integrations.concat(new_integrations)
          application_ids_for_new_integrations = Set.new(new_integrations.flat_map(&:application_ids))
          new_connected_applications = application_ids_for_new_integrations - connected_applications
          connected_applications.merge(application_ids_for_new_integrations)
          break if new_connected_applications.empty? || (max_applications && connected_applications.size >= max_applications)
        end

        integrations.collect(&:id).uniq
      end
      private_class_method :ids_of_integrations_connected_to
    end
  end
end
