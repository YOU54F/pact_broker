require "pact_broker/api/contracts/application_schema"

module PactBroker
  module Api
    module Contracts
      class ApplicationCreateSchema < PactBroker::Api::Contracts::ApplicationSchema
        json do
          required(:name).filled(:string)
        end

        rule(:name).validate(:not_blank_if_present, :not_multiple_lines)
      end
    end
  end
end
