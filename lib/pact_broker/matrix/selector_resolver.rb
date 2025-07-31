require "pact_broker/repositories"
require "pact_broker/matrix/resolved_selector"
require "pact_broker/matrix/resolved_selector_builder"
require "pact_broker/matrix/selector_ignorer"


# Take the selectors and options provided by the user (eg. [{ application_name: "Foo", application_version_number: "1" }], { to_environment: "prod" })
# that use application/version/branch/environment names,
# and look up the IDs of all the objects, and return them as ResolvedSelector objects.
# For unresolved selectors that specify a collection of versions (eg. { branch: "main" }) a ResolvedSelector
# will be returned for every application version found. This will eventually be used in the can-i-deploy
# logic in PactBroker::Matrix::DeploymentStatusSummary to work out if there are any missing verifications.

module PactBroker
  module Matrix
    class SelectorResolver
      class << self
        include PactBroker::Repositories

        # Resolve any ignore selectors used in the can-i-deploy command e.g `--ignore SomeProviderThatIsNotReadyYet`
        # @param [Array<PactBroker::Matrix::UnresolvedSelector>] unresolved_ignore_selectors
        # @return [Array<PactBroker::Matrix::ResolvedSelector>]
        def resolved_ignore_selectors(unresolved_ignore_selectors)
          # When resolving the ignore_selectors, use the NilSelectorIgnorer because it doesn't make sense to ignore
          # the ignore selectors.
          resolve_versions_and_add_ids(unresolved_ignore_selectors, :ignored, NilSelectorIgnorer.new)
        end

        # Resolve the selectors that were specified in the can-i-deploy command eg. `--application Foo --version 43434`
        # There may be one or multiple.
        # @param [Array<PactBroker::Matrix::UnresolvedSelector>] unresolved_specified_selectors
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_ignore_selectors previously resolved selectors for the versions to ignore
        # @return [Array<PactBroker::Matrix::ResolvedSelector>]
        def resolve_specified_selectors(unresolved_specified_selectors, resolved_ignore_selectors)
          resolve_versions_and_add_ids(unresolved_specified_selectors, :specified, SelectorIgnorer.new(resolved_ignore_selectors))
        end

        # When the can-i-deploy command uses any of the `--to` options (eg. `--to-environment ENV` or `--to TAG`)
        # we need to create the inferred selectors for the application versions in that environment/with that tag/branch.
        # eg. if A -> B, and the CLI command is `can-i-deploy --application A --version 3434 --to-environment prod`,
        # then we need to make the inferred selector for application B with the version that is in prod.
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_specified_selectors
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_ignore_selectors
        # @param [Array<PactBroker::Matrix::Integration>] integrations
        # @param [Hash] options
        # @return [Array<PactBroker::Matrix::ResolvedSelector>]
        def resolve_inferred_selectors(resolved_specified_selectors, resolved_ignore_selectors, integrations, options)
          all_application_names = integrations.collect(&:application_names).flatten.uniq
          specified_names = resolved_specified_selectors.collect{ |s| s[:application_name] }
          inferred_application_names = all_application_names - specified_names
          unresolved_selectors = build_unresolved_selectors_for_inferred_applications(inferred_application_names, options)
          resolve_versions_and_add_ids(unresolved_selectors, :inferred, SelectorIgnorer.new(resolved_ignore_selectors))
        end

        # Find the IDs of every application and version in the UnresolvedSelectors, and return them as ResolvedSelectors,
        # expanding selectors for multiple versions.
        # This gets called first for the ignore selectors, then the specified selectors, and then the inferred selectors.
        # When it gets called for the first time for the ignore selectors, they will be passed in as the unresolved_selectors, and the resolved_ignore_selectors
        # will be empty.
        # The next times it is called with the specified selectors and the inferred selectors, the previously resolved ignore selectors will be passed in
        # as resolved_ignore_selectors so we can work out which of those selectors needs to be ignored.
        #
        # @param [Array<PactBroker::Matrix::UnresolvedSelector>] unresolved_selectors
        # @param [Symbol] selector_type which may be :specified or :inferred
        # @param [SelectorIgnorer] selector_ignorer
        # @return [Array<PactBroker::Matrix::ResolvedSelector>]
        def resolve_versions_and_add_ids(unresolved_selectors, selector_type, selector_ignorer)
          applications_hash = find_applications_for_selectors(unresolved_selectors)
          unresolved_selectors.collect do | unresolved_selector |
            build_selectors(applications_hash, unresolved_selector, selector_type, selector_ignorer)
          end.flatten
        end

        private :resolve_versions_and_add_ids

        # Return a Hash of the application names used in the selectors, where the key is the name and the value is the application
        # @return [Hash<String, PactBroker::Domain::Application>]
        def find_applications_for_selectors(unresolved_selectors)
          names = unresolved_selectors.collect(&:application_name)
          PactBroker::Domain::Application.where(name: names).all.group_by(&:name).transform_values(&:first)
        end

        private :find_applications_for_selectors

        def build_selectors(applications_hash, unresolved_selector, selector_type, selector_ignorer)
          selector_builder = ResolvedSelectorBuilder.new(unresolved_selector, selector_type, selector_ignorer)
          selector_builder.application = applications_hash[unresolved_selector.application_name]
          if selector_builder.application
            versions = find_versions_for_selector(unresolved_selector)
            selector_builder.versions = versions
          end
          selector_builder.build
        end

        # Find the application versions for the unresolved selector.
        # @param [PactBroker::Matrix::UnresolvedSelector] unresolved_selector
        def find_versions_for_selector(unresolved_selector)
          # For selectors that just set the application name, there's no need to resolve the version -
          # only the application ID will be used in the query
          return nil if unresolved_selector.all_for_application?
          versions = version_repository.find_versions_for_selector(unresolved_selector)

          if unresolved_selector.latest
            [versions.first]
          else
            versions.empty? ? [nil] : versions
          end
        end

        private :find_versions_for_selector

        # Build an unresolved selector for the integrations that we have inferred for the target environment/branch/tag
        # @param [Array<String>] inferred_application_names the names of the applications that we have determined to be integrated with the versions for the specified selectors
        def build_unresolved_selectors_for_inferred_applications(inferred_application_names, options)
          inferred_application_names.collect do | application_name |
            selector = UnresolvedSelector.new(application_name: application_name)
            selector.tag = options[:tag] if options[:tag]
            selector.branch = options[:branch] if options[:branch]
            selector.main_branch = options[:main_branch] if options[:main_branch]
            selector.latest = options[:latest] if options[:latest]
            selector.environment_name = options[:environment_name] if options[:environment_name]
            selector
          end
        end

        private :build_unresolved_selectors_for_inferred_applications
      end
    end
  end
end
