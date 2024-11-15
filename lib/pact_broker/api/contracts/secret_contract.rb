require "dry-validation"
require "pact_broker/project_root"
require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      class SecretContract < BaseContract

        json do
          required(:name).filled(:string)
          required(:value).maybe(:string)
        end
  
        rule(:name).validate(:not_blank_if_present)
      end
    end
  end
end