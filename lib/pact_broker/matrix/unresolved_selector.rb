require "pact_broker/hash_refinements"

module PactBroker
  module Matrix
    class UnresolvedSelector < Hash
      using PactBroker::HashRefinements

      def initialize(params = {})
        merge!(params)
      end

      # TODO rename branch to branch_name
      def self.from_hash(hash)
        new(hash.symbolize_keys.snakecase_keys.slice(:application_name, :application_version_number, :latest, :tag, :branch, :environment_name, :main_branch))
      end

      def application_name
        self[:application_name]
      end

      def application_version_number
        self[:application_version_number]
      end

      def latest?
        !!latest
      end

      def overall_latest?
        latest? && !tag && !branch
      end

      def latest
        self[:latest]
      end

      def tag
        self[:tag]
      end

      def branch
        self[:branch]
      end

      # @return [Boolean]
      def main_branch
        self[:main_branch]
      end

      def environment_name
        self[:environment_name]
      end

      def latest= latest
        self[:latest] = latest
      end

      def tag= tag
        self[:tag] = tag
      end

      def branch= branch
        self[:branch] = branch
      end

      # @param [Boolean] main_branch
      def main_branch= main_branch
        self[:main_branch] = main_branch
      end

      def environment_name= environment_name
        self[:environment_name] = environment_name
      end

      def application_name= application_name
        self[:application_name] = application_name
      end

      def application_version_number= application_version_number
        self[:application_version_number] = application_version_number
      end

      # TODO delete this once docker image uses new selector class for clean
      def max_age= max_age
        self[:max_age] = max_age
      end

      def max_age
        self[:max_age]
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def all_for_application?
        !!application_name && !application_version_number && !tag && !branch && !latest && !environment_name && !max_age && !main_branch
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def latest_for_application_and_tag?
        !!(application_name && tag && latest)
      end
    end
  end
end
