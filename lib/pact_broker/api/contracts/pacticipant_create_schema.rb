require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Contracts
      class PacticipantCreateSchema
        extend DryValidationWorkarounds
        extend PactBroker::Messages
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation::Contract.build do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end
            required(:name).filled(:str?)
          end

          rule(:name) do
            key.failure(:single_line?) unless DryValidationPredicates.single_line?(value)
          end
        end

        def self.call(params_with_string_keys)
          params = params_with_string_keys&.symbolize_keys
          update_errors = PacticipantSchema::SCHEMA.call(params).messages(full: true)
          create_errors = SCHEMA.call(params).messages(full: true)
          select_first_message(flatten_indexed_messages(update_errors.merge(create_errors)))
        end
      end
    end
  end
end
