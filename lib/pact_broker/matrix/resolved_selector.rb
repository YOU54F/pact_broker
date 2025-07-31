require "pact_broker/hash_refinements"

# A selector with the application id, name, version number, and version id set
# This is created from either specified or inferred data, based on the user's query
# eg.
# can-i-deploy --application Foo --version 1 (this is a specified selector)
#              --to prod (this is used to create inferred selectors, one for each integrated application in that environment)
# When an UnresolvedSelector specifies multiple application versions (eg. { tag: "prod" }) then a ResolvedSelector
# is created for every Version object found for the original selector.

module PactBroker
  module Matrix
    class ResolvedSelector < Hash
      using PactBroker::HashRefinements

      # A version ID of -1 will not match any rows, which is what we want to ensure that
      # no matrix rows are returned for a version that does not exist.
      NULL_VERSION_ID = -1
      NULL_APPLICATION_ID = -1

      def initialize(params = {})
        merge!(params)
      end

      def self.for_application(application, original_selector, type, ignore)
        ResolvedSelector.new(
          application_id: application.id,
          application_name: application.name,
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      # This is not possible for specified selectors, as there is validation at the HTTP query level to
      # ensure that all applications in the specified selectors exist.
      # It is possible for the ignore selectors however.
      def self.for_non_existing_application(original_selector, type, ignore)
        ResolvedSelector.new(
          application_id: NULL_APPLICATION_ID,
          application_name: original_selector[:application_name],
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      # rubocop: disable Metrics/ParameterLists
      def self.for_application_and_version(application, version, original_selector, type, ignore, one_of_many = false)
        ResolvedSelector.new(
          application_id: application.id,
          application_name: application.name,
          application_version_id: version.id,
          application_version_number: version.number,
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch] || (original_selector[:main_branch] ? version&.values[:branch_name] : nil),
          main_branch: original_selector[:main_branch],
          environment_name: original_selector[:environment_name],
          type: type,
          ignore: ignore,
          one_of_many: one_of_many,
          original_selector: original_selector
        )
      end
      # rubocop: enable Metrics/ParameterLists

      def self.for_application_and_non_existing_version(application, original_selector, type, ignore)
        ResolvedSelector.new(
          application_id: application.id,
          application_name: application.name,
          application_version_id: NULL_VERSION_ID,
          application_version_number: original_selector[:application_version_number],
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch],
          main_branch: original_selector[:main_branch],
          environment_name: original_selector[:environment_name],
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      def application_version_specified_in_original_selector?
        !!self.dig(:original_selector, :application_version_number)
      end

      def application_id
        self[:application_id]
      end

      def application_name
        self[:application_name]
      end

      def application_version_id
        self[:application_version_id]
      end

      def application_version_number
        self[:application_version_number]
      end

      def latest?
        self[:latest]
      end

      def tag
        self[:tag]
      end

      # @return [String] the name of the branch
      def branch
        self[:branch]
      end

      # @return [Boolean]
      def main_branch?
        self[:main_branch]
      end

      def environment_name
        self[:environment_name]
      end

      def most_specific_criterion
        if application_version_id
          { application_version_id: application_version_id }
        else
          { application_id: application_id }
        end
      end

      def only_application_name_specified?
        !!application_name && self[:original_selector].without(:application_name).none?{ |_key, value| value }
      end

      def latest_tagged?
        latest? && tag
      end

      def latest_from_branch?
        latest? && branch
      end

      def latest_from_main_branch?
        latest? && main_branch?
      end

      def application_or_version_does_not_exist?
        application_does_not_exist? || version_does_not_exist?
      end

      def application_does_not_exist?
        self[:application_id] == NULL_APPLICATION_ID
      end

      def version_does_not_exist?
        !version_exists?
      end

      def specified_version_that_does_not_exist?
        specified? && version_does_not_exist?
      end

      def version_exists?
        application_version_id != NULL_VERSION_ID
      end

      # Did the user specify this selector in the user's query?
      def specified?
        self[:type] == :specified
      end

      # Was this selector inferred based on the user's query?
      #(ie. the integrations were calculated because only one selector was specified)
      def inferred?
        self[:type] == :inferred
      end

      def one_of_many?
        self[:one_of_many]
      end

      def ignore?
        self[:ignore]
      end

      def consider?
        !ignore?
      end

      def original_selector
        self[:original_selector]
      end

      # rubocop: disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def description
        if latest_tagged? && application_version_number
          "the latest version of #{application_name} with tag #{tag} (#{application_version_number})"
        elsif latest_tagged?
          "the latest version of #{application_name} with tag #{tag} (no such version exists)"
        elsif latest_from_main_branch? && application_version_number.nil?
          "the latest version of #{application_name} from the main branch (no versions exist for this branch)"
        elsif main_branch? && application_version_number.nil?
          "any version of #{application_name} from the main branch (no versions exist for this branch)"
        elsif latest_from_branch? && application_version_number
          "the latest version of #{application_name} from branch #{branch} (#{application_version_number})"
        elsif latest_from_branch?
          "the latest version of #{application_name} from branch #{branch} (no such version exists)"
        elsif branch && application_version_number
          prefix = one_of_many? ? "one of the versions " : "the version "
          prefix + "of #{application_name} from branch #{branch} (#{application_version_number})"
        elsif branch
          "a version of #{application_name} from branch #{branch} (no such version exists)"
        elsif latest? && application_version_number
          "the latest version of #{application_name} (#{application_version_number})"
        elsif latest?
          "the latest version of #{application_name} (no such version exists)"
        elsif tag && application_version_number
          "a version of #{application_name} with tag #{tag} (#{application_version_number})"
        elsif tag
          "a version of #{application_name} with tag #{tag} (no such version exists)"
        elsif environment_name && application_version_number
          prefix = one_of_many? ? "one of the versions" : "the version"
          "#{prefix} of #{application_name} currently in #{environment_name} (#{application_version_number})"
        elsif environment_name
          "a version of #{application_name} currently in #{environment_name} (no version is currently recorded as deployed/released in this environment)"
        elsif application_version_number && version_does_not_exist?
          "version #{application_version_number} of #{application_name} (no such version exists)"
        elsif application_version_number
          "version #{application_version_number} of #{application_name}"
        elsif application_does_not_exist?
          "any version of #{application_name} (no such application exists)"
        else
          "any version of #{application_name}"
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def version_does_not_exist_description
        if version_does_not_exist?
          if tag
            "No version with tag #{tag} exists for #{application_name}"
          elsif branch
            "No version of #{application_name} from branch #{branch} exists"
          elsif main_branch?
            "No version of #{application_name} from the main branch exists"
          elsif environment_name
            "No version of #{application_name} is currently recorded as deployed or released in environment #{environment_name}"
          elsif application_version_number
            "No pacts or verifications have been published for version #{application_version_number} of #{application_name}"
          else
            "No pacts or verifications have been published for #{application_name}"
          end
        else
          ""
        end
      end
    end
  end
end
