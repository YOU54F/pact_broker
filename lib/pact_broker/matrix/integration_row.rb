# A Sequel model used for identifying potential and required integrations
# between the versions described by the specified selectors
# and other applications.
# It is only meant to be used via the public dataset methods.

module PactBroker
  module Matrix
    class IntegrationRow < Sequel::Model(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :p))
      dataset_module do
        select(:select_application_ids, Sequel[:p][:consumer_id], Sequel[:p][:provider_id])

        # Return the distinct consumer/provider ids and names for the integrations which involve the given resolved selector
        # in the role of consumer. The resolved selector must have a application_id, and may or may not have a application_version_id.
        # @public
        # @param [PactBroker::Matrix::ResolvedSelector] resolved_selector
        # @return [Sequel::Dataset] for rows with consumer_id, consumer_name, provider_id and provider_name
        def integrations_for_selector_as_consumer(resolved_selector)
          select(:consumer_id, :provider_id)
            .distinct
            .where({ consumer_id: resolved_selector.application_id, consumer_version_id: resolved_selector.application_version_id }.compact)
            .from_self(alias: :integrations)
            .select(:consumer_id, :provider_id, Sequel[:consumers][:name].as(:consumer_name), Sequel[:providers][:name].as(:provider_name))
            .join_consumers(:integrations, :consumers)
            .join_providers(:integrations, :providers)
        end

        # Find all the integrations (consumer/provider pairs) that involve ONLY the given selectors.
        # @public
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
        # @return [Sequel::Dataset] for rows with consumer_id, consumer_name, provider_id and provider_name
        def distinct_integrations_between_given_selectors(resolved_selectors)
          if resolved_selectors.size == 1
            raise ArgumentError.new("Expected multiple selectors to be provided, but only received one #{selectors}")
          end
          query = pact_publications_matching_selectors_as_consumer(resolved_selectors)
                    .select_application_ids
                    .distinct

          query.from_self(alias: :application_ids)
            .select(
              :consumer_id,
              Sequel[:c][:name].as(:consumer_name),
              :provider_id,
              Sequel[:p][:name].as(:provider_name)
            )
            .join_consumers(:application_ids, :c)
            .join_providers(:application_ids, :p)
        end

        # @public
        def join_consumers qualifier = :p, table_alias = :consumers
          join(
            :applications,
            { Sequel[qualifier][:consumer_id] => Sequel[table_alias][:id] },
            { table_alias: table_alias }
          )
        end

        # @public
        def join_providers qualifier = :p, table_alias = :providers
          join(
            :applications,
            { Sequel[qualifier][:provider_id] => Sequel[table_alias][:id] },
            { table_alias: table_alias }
          )
        end

        # @private
        def pact_publications_matching_selectors_as_consumer(resolved_selectors)
          application_ids = resolved_selectors.collect(&:application_id).uniq

          self
            .select_application_ids
            .distinct
            .inner_join_versions_for_selectors_as_consumer(resolved_selectors)
            .where(provider_id: application_ids)
        end

        # @private
        def inner_join_versions_for_selectors_as_consumer(resolved_selectors)
          # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
          unresolved_selectors = resolved_selectors.collect(&:original_selector).uniq
          versions = PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors)
          inner_join_versions_dataset(versions)
        end

        # @private
        def inner_join_versions_dataset(versions)
          versions_join = { Sequel[:p][:consumer_version_id] => Sequel[:versions][:id] }
          join(versions, versions_join, table_alias: :versions)
        end
      end
    end
  end
end
