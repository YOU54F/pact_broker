require "pact_broker/domain/label"

module PactBroker
  module Labels
    class Repository

      def get_all_unique_labels pagination_options = {}
        PactBroker::Domain::Label.distinct.select(:name).order(:name).all_with_pagination_options(pagination_options)
      end

      def create args
        Domain::Label.new(name: args.fetch(:name), application: args.fetch(:application)).save
      end

      def find args
        PactBroker::Domain::Label
          .select_all_qualified
          .join(:applications, { id: :application_id })
          .where(Sequel.name_like(Sequel.qualify("labels", "name"), args.fetch(:label_name)))
          .where(Sequel.name_like(Sequel.qualify("applications", "name"), args.fetch(:application_name)))
          .single_record
      end

      def delete args
        find(args).delete
      end

      def delete_by_application_id application_id
        Sequel::Model.db[:labels].where(application_id: application_id).delete
      end
    end
  end
end
