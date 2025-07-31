require "pact_broker/api/decorators/applications_decorator"
require "pact_broker/domain/application"

module PactBroker
  module Api
    module Decorators
      describe ApplicationsDecorator do
        let(:options) { {user_options: {base_url: "http://example.org"} } }
        let(:applications) { [] }
        let(:json) { ApplicationsDecorator.new(applications).to_json(**options) }

        subject { JSON.parse json, symbolize_names: true }

        it "includes a link to find applications by label" do
          expect(subject[:_links][:'pb:applications-with-label'][:href]).to match %r{http://.*label/{label}}
        end

        context "with no applications" do
          it "doesn't blow up" do
            subject
          end
        end

        context "with applications" do
          let(:application) { PactBroker::Domain::Application.new(name: "Name", created_at: DateTime.new, updated_at: DateTime.new)}
          let(:applications) { [application] }

          it "displays a list of applications" do
            expect(subject[:_embedded][:applications]).to be_instance_of(Array)
            expect(subject[:_embedded][:applications].size).to eq 1
          end
        end
      end

      describe DeprecatedApplicationsDecorator do
        let(:options) { { user_options: { base_url: base_url } } }
        let(:application) { PactBroker::Domain::Application.new(name: "Name", created_at: DateTime.new, updated_at: DateTime.new)}
        let(:applications) { [application] }
        let(:base_url) { "http://example.org" }
        let(:json) { DeprecatedApplicationsDecorator.new(applications).to_json(**options) }

        subject { JSON.parse(json, symbolize_names: true) }

        it "includes the applications under the _embedded key" do
          expect(subject[:_embedded][:applications]).to be_instance_of(Array)
        end

        it "includes the applications under the applications key" do
          expect(subject[:applications]).to be_instance_of(Array)
        end

        it "includes a deprecation warning in the applications links" do
          expect(subject[:_links][:applications].first[:name]).to include "DEPRECATED"
        end

        it "includes a deprecation warning in the non-embedded application title" do
          expect(subject[:applications].first[:title]).to include "DEPRECATED"
        end

        it "passes in the options correctly (Representable does inconsistent things with the args of to_json and to_hash)" do
          allow_any_instance_of(PactBroker::Api::PactBrokerUrls). to receive(:applications_url) do | _instance, actual_base_url |
            @actual_base_url = actual_base_url
            ""
          end
          subject
          expect(@actual_base_url).to eq base_url
        end
      end
    end
  end
end
