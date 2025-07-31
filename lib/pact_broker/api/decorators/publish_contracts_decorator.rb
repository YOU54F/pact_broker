require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/publish_contract_decorator"
require "pact_broker/contracts/contract_to_publish"

module PactBroker
  module Api
    module Decorators
      class PublishContractsDecorator < BaseDecorator
        camelize_property_names

        property :application_name
        property :application_version_number
        property :tags
        property :branch
        property :build_url

        collection :contracts, :extend => PublishContractDecorator, class: PactBroker::Contracts::ContractToPublish
      end
    end
  end
end
