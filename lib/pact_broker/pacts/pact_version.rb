require "sequel"
require "pact_broker/repositories/helpers"
require "pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version"
require "pact_broker/pacts/content"

module PactBroker
  module Pacts
    class PactVersion < Sequel::Model(:pact_versions)
      plugin :timestamps
      plugin :upsert, identifying_columns: [:consumer_id, :provider_id, :sha]

      one_to_many :pact_publications, reciprocal: :pact_version
      one_to_many :verifications, reciprocal: :verification, order: :id, class: "PactBroker::Domain::Verification"
      associate(:many_to_one, :provider, class: "PactBroker::Domain::Pacticipant", key: :provider_id, primary_key: :id)
      associate(:many_to_one, :consumer, class: "PactBroker::Domain::Pacticipant", key: :consumer_id, primary_key: :id)
      associate(:many_to_many, :consumer_versions, class: "PactBroker::Domain::Version", join_table: :pact_publications, left_key: :pact_version_id, right_key: :consumer_version_id, order: :order)

      one_to_one(:latest_verification,
        class: "PactBroker::Domain::Verification",
        read_only: true,
        dataset: lambda { PactBroker::Domain::Verification.where(id: PactBroker::Verifications::LatestVerificationIdForPactVersionAndProviderVersion.select(Sequel.function(:max, :verification_id)).where(pact_version_id: id)) },
        key: :pact_version_id, primary_key: :id,
        eager_block: lambda { | ds | ds.latest_by_pact_version }
      )

      # do not eager load this - it won't work because of the limit(1)
      one_through_one(:latest_consumer_version, class: "PactBroker::Domain::Version", join_table: :pact_publications, left_key: :pact_version_id, right_key: :consumer_version_id) do | ds |
        ds.unlimited.order(Sequel.desc(:order)).limit(1)
      end

      dataset_module do
        include PactBroker::Repositories::Helpers

        def for_pact_domain(pact_domain)
          where(
            sha: pact_domain.pact_version_sha,
            consumer_id: pact_domain.consumer.id,
            provider_id: pact_domain.provider.id
          ).single_record
        end

        def join_successful_verifications
          verifications_join = {
            Sequel[:verifications][:pact_version_id] => Sequel[:pact_versions][:id],
            Sequel[:verifications][:success] => true
          }
          join(:verifications, verifications_join)
        end

        def join_provider_versions
          join(:versions, { Sequel[:provider_versions][:id] => Sequel[:verifications][:provider_version_id] }, { table_alias: :provider_versions })
        end

        def join_provider_version_tags_for_tag(tag)
          tags_join = {
            Sequel[:tags][:version_id] => Sequel[:provider_versions][:id],
            Sequel[:tags][:name] => tag
          }
          join(:tags, tags_join)
        end
      end

      def name
        "Pact between #{consumer_name} and #{provider_name}"
      end

      def provider_name
        pact_publications.last.provider.name
      end

      def consumer_name
        pact_publications.last.consumer.name
      end

      def latest_pact_publication
        PactBroker::Pacts::PactPublication
          .for_pact_version_id(id)
          .remove_overridden_revisions_from_complete_query
          .latest || PactBroker::Pacts::PactPublication.for_pact_version_id(id).latest
      end


      def latest_consumer_version_number
        latest_consumer_version.number
      end

      def select_provider_tags_with_successful_verifications_from_another_branch_from_before_this_branch_created(tags)
        tags.select do | tag |
          first_tag_with_name = PactBroker::Domain::Tag.where(pacticipant_id: provider_id, name: tag).order(:created_at).first

          verifications_join = {
            Sequel[:verifications][:pact_version_id] => Sequel[:pact_versions][:id],
            Sequel[:verifications][:success] => true
          }
          tags_join = {
            Sequel[:tags][:version_id] => Sequel[:versions][:id],
          }
          query = PactVersion.where(Sequel[:pact_versions][:id] => id)
            .join(:verifications, verifications_join)
            .join(:versions, Sequel[:versions][:id] => Sequel[:verifications][:provider_version_id])
            .join(:tags, tags_join) do
              Sequel.lit("tags.name != ?", tag)
            end

          if first_tag_with_name
            query = query.where { Sequel[:verifications][:created_at] < first_tag_with_name.created_at }
          end

          query.any?
        end
      end

      def select_provider_tags_with_successful_verifications(tags)
        tags.select do | tag |
          PactVersion.where(Sequel[:pact_versions][:id] => id)
            .join_successful_verifications
            .join_provider_versions
            .join_provider_version_tags_for_tag(tag)
            .any?
        end
      end

      def verified_successfully_by_any_provider_version?
        PactVersion.where(Sequel[:pact_versions][:id] => id)
          .join_successful_verifications
          .any?
      end

      def set_interactions_and_messages_counts!
        if interactions_count.nil? || messages_count.nil?
          content_object = PactBroker::Pacts::Content.from_json(content)
          update(
            messages_count: content_object.messages&.count || 0,
            interactions_count: content_object.interactions&.count || 0
          )
        end
      end
    end
  end
end

# Table: pact_versions
# Columns:
#  id                 | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  consumer_id        | integer                     | NOT NULL
#  provider_id        | integer                     | NOT NULL
#  sha                | text                        | NOT NULL
#  content            | text                        |
#  created_at         | timestamp without time zone | NOT NULL
#  messages_count     | integer                     |
#  interactions_count | integer                     |
# Indexes:
#  pact_versions_pkey   | PRIMARY KEY btree (id)
#  unq_pvc_con_prov_sha | UNIQUE btree (consumer_id, provider_id, sha)
# Foreign key constraints:
#  pact_versions_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id)
#  pact_versions_provider_id_fkey | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  latest_pact_publication_ids_for_consumer_versions            | latest_pact_publication_ids_for_consumer_v_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_pact_version_id_fk                    | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  pact_publications                                            | pact_publications_pact_version_id_fkey                          | (pact_version_id) REFERENCES pact_versions(id)
#  verifications                                                | verifications_pact_version_id_fkey                              | (pact_version_id) REFERENCES pact_versions(id)
