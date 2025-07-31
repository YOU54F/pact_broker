require "pact_broker/domain/application"
require "pact_broker/error"
require "pact_broker/repositories/scopes"

module PactBroker
  module Applications
    class Repository

      include PactBroker::Repositories
      include PactBroker::Repositories::Scopes

      def find_by_name name
        applications = PactBroker::Domain::Application.where(Sequel.name_like(:name, name)).all
        handle_multiple_applications_found(name, applications) if applications.size > 1
        applications.first
      end

      def find_by_name! name
        application = find_by_name(name)
        raise PactBroker::Error, "No application found with name '#{name}'" unless application
        application
      end

      # @param [Array<String>] the array of names by which to find the applications
      def find_by_names(names)
        return [] if names.empty?
        name_likes = names.collect{ | name | Sequel.name_like(:name, name) }
        scope_for(PactBroker::Domain::Application).where(Sequel.|(*name_likes)).all
      end

      def find_by_id id
        PactBroker::Domain::Application.where(id: id).single_record
      end

      def find_all(options = {}, pagination_options = {}, eager_load_associations = [])
        find(options, pagination_options, eager_load_associations)
      end

      def find(options = {}, pagination_options = {}, eager_load_associations = [])
        query = scope_for(PactBroker::Domain::Application)
        return [] if query.empty?

        query = query.select_all_qualified
        query = query.filter(:name, options[:query_string]) if options[:query_string]
        query = query.label(options[:label_name]) if options[:label_name]
        query.order_ignore_case(Sequel[:applications][:name]).eager(*eager_load_associations).all_with_pagination_options(pagination_options)
      end

      def find_by_name_or_create name
        application = find_by_name(name)
        application ? application : create(name: name)
      end

      # Need to be able to handle two calls that make the application at the same time.
      # TODO raise error if attributes apart from name are different, because this indicates that
      # the second request is not at the same time.
      def create params
        PactBroker::Domain::Application.new(
          name: params.fetch(:name),
          display_name: params[:display_name],
          repository_url: params[:repository_url],
          repository_name: params[:repository_name],
          repository_namespace: params[:repository_namespace],
          main_branch: params[:main_branch]
        ).insert_ignore.refresh
      end

      def update(application_name, application)
        application.name = application_name
        application.save.refresh
      end

      def replace(application_name, open_struct_application)
        PactBroker::Domain::Application.new(
          name: application_name,
          display_name: open_struct_application.display_name,
          repository_url: open_struct_application.repository_url,
          repository_name: open_struct_application.repository_name,
          repository_namespace: open_struct_application.repository_namespace,
          main_branch: open_struct_application.main_branch
        ).upsert
      end

      def delete(application)
        application.destroy
      end

      def application_names
        PactBroker::Domain::Application.select(:name).order(:name).collect(&:name)
      end

      def delete_if_orphan(application)
        if PactBroker::Domain::Version.where(application: application).empty? &&
          PactBroker::Pacts::PactPublication.where(provider: application).or(consumer: application).empty? &&
            PactBroker::Pacts::PactVersion.where(provider: application).or(consumer: application).empty? &&
            PactBroker::Webhooks::Webhook.where(provider: application).or(consumer: application).empty?
          application.destroy
        end
      end

      def handle_multiple_applications_found(name, applications)
        names = applications.collect(&:name).join(", ")
        raise PactBroker::Error.new("Found multiple applications with a case insensitive name match for '#{name}': #{names}. Please delete one of them, or set PactBroker.configuration.use_case_sensitive_resource_names = true")
      end

      def search_by_name(application_name)
        terms = application_name.split.map { |v| v.gsub("_", "\\_") }
        columns = [:name, :display_name]
        string_match_query = Sequel.|(
          *terms.map do |term|
            Sequel.|(
              *columns.map do |column|
                Sequel.ilike(Sequel[:applications][column], "%#{term}%")
              end
            )
          end
        )
        scope_for(PactBroker::Domain::Application).where(string_match_query)
      end

      def set_main_branch(application, main_branch)
        application.update(main_branch: main_branch)
      end
    end
  end
end
