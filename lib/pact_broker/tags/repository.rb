require "pact_broker/domain/tag"
require "pact_broker/repositories"

module PactBroker
  module Tags
    class Repository
      include PactBroker::Repositories

      def create args
        params = {
          name: args.fetch(:name),
          version_id: args.fetch(:version).id,
          version_order: args.fetch(:version).order,
          application_id: args.fetch(:version).application_id
        }
        Domain::Tag.new(params).insert_ignore
      end

      def find args
        PactBroker::Domain::Tag
          .select_all_qualified
          .join(:versions, { id: :version_id })
          .join(:applications, {Sequel.qualify("applications", "id") => Sequel.qualify("versions", "application_id")})
          .where(Sequel.name_like(Sequel.qualify("tags", "name"), args.fetch(:tag_name)))
          .where(Sequel.name_like(Sequel.qualify("versions", "number"), args.fetch(:application_version_number)))
          .where(Sequel.name_like(Sequel.qualify("applications", "name"), args.fetch(:application_name)))
          .single_record
      end

      def delete_by_version_id version_id
        Domain::Tag.where(version_id: version_id).delete
      end

      def find_all_tag_names_for_application application_name
        PactBroker::Domain::Tag
        .select(Sequel[:tags][:name])
        .join(:versions, { Sequel[:versions][:id] => Sequel[:tags][:version_id] })
        .join(:applications, { Sequel[:applications][:id] => Sequel[:versions][:application_id] })
        .where(Sequel[:applications][:name] => application_name)
        .distinct
        .collect{ |tag| tag[:name] }.sort
      end

      def find_all_by_application_name_and_tag(application_name, tag_name)
        application = application_repository.find_by_name(application_name)
        return PactBroker::Domain::Tag.where(application_id: application.id, name: tag_name) if application

        []
      end

    end
  end
end
