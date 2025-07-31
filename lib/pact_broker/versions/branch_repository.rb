require "pact_broker/repositories/scopes"
module PactBroker
  module Versions
    class BranchRepository
      include PactBroker::Services
      include PactBroker::Repositories::Scopes

      # @param [PactBroker::Domain::Application] application
      # @param [Hash] filter_options with key :query_string
      # @param [Hash] pagination_options with keys :page_size and :page_number
      # @param [Array] eager_load_associations the associations to eager load
      def find_all_branches_for_application(application, filter_options = {}, pagination_options = {}, eager_load_associations = [])
        query = scope_for(Branch).where(application_id: application.id).select_all_qualified
        query = query.filter(:name, filter_options[:query_string]) if filter_options[:query_string]
        query
          .order(Sequel.desc(:created_at), Sequel.desc(:id))
          .eager(*eager_load_associations)
          .all_with_pagination_options(pagination_options)
      end

      # @param [String] application_name
      # @param [String] branch_name
      # @return [PactBroker::Versions::Branch, nil]
      def find_branch(application_name:, branch_name:)
        Branch
          .select_all_qualified
          .join(:applications, { Sequel[:branches][:application_id] => Sequel[:applications][:id] }) do
            Sequel.name_like(Sequel[:applications][:name], application_name)
          end
          .where(Sequel[:branches][:name] => branch_name)
          .single_record
      end

      # Deletes a branch, its branch head and branch_version objects, without deleting the
      # application version objects
      #
      # @param [PactBroker::Versions::Branch] the branch to delete
      def delete_branch(branch)
        branch.delete
      end

      # @param [PactBroker::Domain::Application] application
      # @params [Array<String>] exclude the names of the branches to NOT delete
      # @param [Integer] the number of branches that will be deleted
      def count_branches_to_delete(application, exclude: )
        build_query_for_application_branches(application, exclude: exclude).count
      end

      # Returns the list of branches which will NOT be deleted (the bulk delete is executed async after the request has finished)
      # @param [PactBroker::Domain::Application] application
      # @params [Array<String>] exclude the names of the branches to NOT delete
      # @return [Array<PactBroker::Versions::Branch>]
      def remaining_branches_after_future_deletion(application, exclude: )
        exclude_dup = exclude.dup
        if application.main_branch
          exclude_dup << application.main_branch
        end
        Branch.where(application_id: application.id).where(name: exclude_dup)
      end

      # @param [PactBroker::Domain::Application] application
      # @params [Array<String>] exclude the names of the branches to NOT delete
      def delete_branches_for_application(application, exclude:)
        build_query_for_application_branches(application, exclude: exclude).delete
      end

      def build_query_for_application_branches(application, exclude: )
        exclude_dup = exclude.dup
        if application.main_branch
          exclude_dup << application.main_branch
        end
        Branch.where(application_id: application.id).exclude(name: exclude_dup)
      end
    end
  end
end
