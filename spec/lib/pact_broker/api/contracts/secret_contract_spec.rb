require "pact_broker/api/contracts/secret_contract"
require "pact_broker/project_root"

module PactBroker
  module Api
    module Contracts
      describe SecretContract do
        include PactBroker::Test::ApiContractSupport
        let(:params) { {} }
        let(:secret_contract) { SecretContract.new }
        subject { format_errors_the_old_way(SecretContract.call(params)) }

        context "with empty params" do
          it "has errors" do
            is_expected.to eq({ name: ["is missing"], value: ["is missing"] })
          end
        end

        context "when required params are present but blank" do
          let(:params) do
            {
              name: " ",
              value: ""
            }
          end

          it "has an error for the name but not the value" do
            is_expected.to include(name: ["cannot be blank"])
            is_expected.to_not include(:value)
          end
        end
      end
    end
  end
end