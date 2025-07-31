require "pact_broker/api/resources/can_i_merge_badge"
require "pact_broker/api/resources/base_resource"

module PactBroker
  module Api
    module Resources
      describe CanIMergeBadge do
        before do
          allow_any_instance_of(described_class).to receive(:badge_service).and_return(badge_service)

          allow(badge_service). to receive(:can_i_merge_badge_url).and_return("http://badge_url")
          allow(badge_service). to receive(:error_badge_url).and_return("http://error_badge_url")

          allow_any_instance_of(CanIMergeBadge).to receive(:application).and_return(application)
          allow_any_instance_of(CanIMergeBadge).to receive(:version).and_return(version)
          allow_any_instance_of(CanIMergeBadge).to receive(:results).and_return(results)
        end

        let(:branch_service) { class_double("PactBroker::Versions::BranchService").as_stubbed_const }
        let(:badge_service) { class_double("PactBroker::Badges::Service").as_stubbed_const }

        let(:application) { double("application") }
        let(:version) { double("version", number: "1") }
        let(:results) { true }

        let(:path) { "/applications/Foo/main-branch/can-i-merge/badge" }

        subject { get(path) }

        context "when everything is found" do
          it "returns a 307" do
            expect(subject.status).to eq 307
          end

          it "return the badge URL" do
            expect(badge_service). to receive(:can_i_merge_badge_url).with(deployable: true)
            expect(subject.headers["Location"]).to eq "http://badge_url"
            expect(subject.headers["cache-control"]).to eq "max-age=30"
          end
        end

        context "when the application is not found" do
          let(:application) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("application", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
            expect(subject.headers["cache-control"]).to eq "no-cache"  
          end
        end

        context "when the version is not found" do
          let(:version) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("main branch version", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end
      end
    end
  end
end
