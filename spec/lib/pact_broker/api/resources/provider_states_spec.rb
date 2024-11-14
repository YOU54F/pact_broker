require "pact_broker/api/resources/provider_states"

module PactBroker
  module Api
    module Resources
      describe ProviderStates do
        before do
          # Delete this when the route has been added to the API
          allow_any_instance_of(described_class).to receive(:application_context).and_return(PactBroker::ApplicationContext.default_application_context)
          allow_any_instance_of(described_class).to receive(:provider_states_service).and_return(provider_states_service)
          allow(provider_states_service).to receive(:find_by_uuid).and_return(provider_states)
          allow(PactBroker::Api::Decorators::ProviderStatesDecorator).to receive(:new).and_return(decorator)
        end

        let(:provider_states) { instance_double("PactBroker::Pacts::ProviderStates") }
        let(:parsed_provider_states) { double("parsed provider_states") }
        let(:provider_states_service) { class_double("PactBroker::Pacts::Service").as_stubbed_const }
        let(:path) { "/provider-statess/#{uuid}" }
        let(:uuid) { "12345678" }
        let(:rack_headers) do
          {
            "HTTP_ACCEPT" => "application/hal+json"
          }
        end
        let(:decorator) do
          instance_double("PactBroker::Api::Decorators::ProviderStatesDecorator",
            to_json: "response",
            from_json: parsed_provider_states
          )
        end

        # Delete this when the route has been added to the API - this is just here so that the generated
        # spec can be run to see if it works.
        let(:app) do
          pact_api = Webmachine::Application.new do |app|
            app.routes do
              add ["provider-statess", :provider_states_uuid], PactBroker::Api::Resources::ProviderStates, { resource_name: "provider_states" }
            end
          end
          pact_api.configure do |config|
            config.adapter = :RackMapped
          end

          pact_api.adapter
        end

        describe "GET" do
          subject { get(path, nil, rack_headers) }

          it "attempts to find the ProviderStates" do
            expect(PactBroker::Pacts::Service).to receive(:find_by_uuid).with(uuid)
            subject
          end

          context "when the provider_states does not exist" do
            let(:provider_states) { nil }

            it { is_expected.to be_a_404_response }
          end

          context "when the ProviderStates exists" do
            it "generates a JSON representation of the ProviderStates" do
              expect(PactBroker::Api::Decorators::ProviderStatesDecorator).to receive(:new).with(provider_states)
              expect(decorator).to receive(:to_json).with(user_options: hash_including(base_url: "http://example.org"))
              subject
            end

            it { is_expected.to be_a_hal_json_success_response }

            it "includes the JSON representation in the response body" do
              expect(subject.body).to eq "response"
            end
          end
        end
      end
    end
  end
end