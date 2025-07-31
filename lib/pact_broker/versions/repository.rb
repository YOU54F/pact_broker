require "pact_broker/logging"
require "pact_broker/domain/version"
require "pact_broker/tags/repository"
require "pact_broker/versions/branch"
require "pact_broker/versions/branch_version"
require "pact_broker/versions/branch_head"

module PactBroker
  module Versions
    class Repository

      include PactBroker::Logging
      include PactBroker::Repositories

      def find_by_application_id_and_number application_id, number
        PactBroker::Domain::Version.where(number: number, application_id: application_id).single_record
      end

      def find_by_application_name_and_latest_tag application_name, tag
        PactBroker::Domain::Version
          .select_all_qualified
          .where_tag(tag)
          .where_application_name(application_name)
          .reverse_order(:order)
          .first
      end

      def find_latest_by_application_name_and_branch_name(application_name, branch_name)
        branch_heads_join = { Sequel[:versions][:id] => Sequel[:branch_heads][:version_id], Sequel[:branch_heads][:branch_name] => branch_name }
        PactBroker::Domain::Version
          .where_application_name(application_name)
          .join(:branch_heads, branch_heads_join)
          .single_record
      end

      def find_by_application_name_and_tag application_name, tag
        PactBroker::Domain::Version
          .select_all_qualified
          .where_application_name(application_name)
          .where_tag(tag)
          .all
      end

      def find_latest_by_pacticpant_name application_name
        PactBroker::Domain::Version
          .select_all_qualified
          .where_application_name(application_name)
          .reverse_order(:order)
          .first
      end

      def find_by_application_name_and_number application_name, number
        PactBroker::Domain::Version
          .select_all_qualified
          .where_application_name(application_name)
          .where_number(number)
          .single_record
      end

      def find_application_versions_in_reverse_order(application_name, options = {}, pagination_options = {}, eager_load_associations = [])
        application = application_repository.find_by_name!(application_name)
        query = PactBroker::Domain::Version
                  .where(application: application)
                  .eager(*eager_load_associations)
                  .reverse_order(:order)

        if options[:branch_name]
          query = query.where_branch_name(options[:branch_name])
        end
        query.all_with_pagination_options(pagination_options)
      end

      # There may be a race condition if two simultaneous requests come in to create the same version
      def create(args)
        version_params = {
          number: args[:number],
          application_id: args[:application_id],
          created_at: Sequel.datetime_class.now,
          updated_at: Sequel.datetime_class.now,
          build_url: args[:build_url]
        }.compact


        version = PactBroker::Domain::Version.new(version_params).upsert
        # branch can't be set from CRUD on the version resource, but it's convenient to be able
        # to make a version with a branch for internal code.
        branch_version_repository.add_branch(version, args[:branch]) if args[:branch]
        version
      end

      def create_or_update(application, version_number, open_struct_version)
        saved_version = PactBroker::Domain::Version.where(application_id: application.id, number: version_number).single_record
        params = open_struct_version.to_h
        tags = params.delete(:tags)
        branch_name = params.delete(:branch)
        if saved_version
          saved_version.update(params)
        else
          # Upsert is only for race conditions
          # Upsert blanks out any fields that are not provided
          saved_version = PactBroker::Domain::Version.new(
            params.merge(
              application_id: application.id,
              number: version_number
            ).compact
          ).upsert
        end

        branch_version_repository.add_branch(saved_version, branch_name) if branch_name
        replace_tags(saved_version, tags) if tags
        saved_version
      end

      def create_or_overwrite(application, version_number, open_struct_version)
        saved_version = PactBroker::Domain::Version.new(
          number: version_number,
          application: application,
          build_url: open_struct_version.build_url
        ).upsert

        if open_struct_version.tags
          replace_tags(saved_version, open_struct_version.tags)
        end

        saved_version
      end

      def replace_tags(saved_version, open_struct_tags)
        tag_repository.delete_by_version_id(saved_version.id)
        open_struct_tags.collect do | open_struct_tag |
          tag_repository.create(version: saved_version, name: open_struct_tag.name)
        end
        saved_version.refresh
      end

      def find_by_application_id_and_number_or_create application_id, number
        version = find_by_application_id_and_number(application_id, number)

        version ? version : create(application_id: application_id, number: number)
      end

      def delete_by_id version_ids
        branches = Versions::Branch.where(id: Versions::BranchHead.select(:branch_id).where(version_id: version_ids)).all # these will be deleted
        Domain::Version.where(id: version_ids).delete
        branches.each do | branch |
          new_head_branch_version = Versions::BranchVersion.find_latest_for_branch(branch)
          if new_head_branch_version
            PactBroker::Versions::BranchHead.new(branch: branch, branch_version: new_head_branch_version).upsert
          end
        end
        nil
      end

      def delete_orphan_versions consumer, provider
        version_ids_with_pact_publications = PactBroker::Pacts::PactPublication.where(consumer_id: [consumer.id, provider.id]).select(:consumer_version_id).collect{|r| r[:consumer_version_id]}
        version_ids_with_verifications = PactBroker::Domain::Verification.where(provider_id: [provider.id, consumer.id]).select(:provider_version_id).collect{|r| r[:provider_version_id]}
        # Hope we don't hit max parameter constraints here...
        PactBroker::Domain::Version
          .where(Sequel[:versions][:application_id] => [consumer.id, provider.id])
          .exclude(id: (version_ids_with_pact_publications + version_ids_with_verifications).uniq)
          .delete
      end

      def find_versions_for_selector(selector)
        PactBroker::Domain::Version.select_all_qualified.for_selector(selector).all
      end

      def find_latest_version_from_main_branch(application)
        if application.main_branch
          latest_from_main_branch = PactBroker::Domain::Version
            .latest_versions_for_application_branches(application.id, application.main_branch)
            .single_record

          latest_from_main_branch || find_by_application_name_and_latest_tag(application.name, application.main_branch)
        end
      end

      def find_by_ids_in_reverse_order version_ids, pagination_options = {}, eager_load_associations =[]
        query = PactBroker::Domain::Version
                  .where(id: version_ids)
                  .eager(*eager_load_associations)
                  .reverse_order(:order)

        query.all_with_pagination_options(pagination_options)
      end
    end
  end
end
