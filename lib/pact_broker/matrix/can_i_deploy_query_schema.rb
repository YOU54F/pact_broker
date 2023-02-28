require "dry-validation"
require "dry/schema"
require "pact_broker/messages"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/project_root"
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Contracts
      class CanIDeployQuerySchema
        extend PactBroker::Messages
        using PactBroker::StringRefinements

        SCHEMA = Dry::Validation::Contract.build do
          schema do
            configure do
              config.messages.load_paths << PactBroker.project_root.join("lib", "pact_broker", "locale", "en.yml")
            end
            required(:pacticipant).filled(:str?)
            required(:version).filled(:str?)
            optional(:to).filled(:str?)
            optional(:environment).filled(:str?)
          end

          rule(:environment) do
            key.failure(:environment_with_name_exists?) if key? &&
              !DryValidationPredicates.environment_with_name_exists?(value)
          end
        end

        def self.call(params)
          result = select_first_message(SCHEMA.call(params).messages(full: true))
          if params[:to] && params[:environment]
            result[:to] ||= []
            result[:to] << message("errors.validation.cannot_specify_tag_and_environment")
          end
          if params[:to].blank? && params[:environment].blank?
            result[:environment] ||= []
            result[:environment] << message("errors.validation.must_specify_environment_or_tag")
          end
          result
        end

        def self.select_first_message(messages)
          messages.each_with_object({}) do | (key, value), new_messages |
            new_messages[key] = [value.first]
          end
        end
      end
    end
  end
end
