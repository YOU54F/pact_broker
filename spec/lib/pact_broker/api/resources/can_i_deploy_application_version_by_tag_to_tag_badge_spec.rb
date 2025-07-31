require "pact_broker/api/resources/can_i_deploy_application_version_by_tag_to_tag_badge"

module PactBroker
  module Api
    module Resources
      describe CanIDeployApplicationVersionByTagToTagBadge do
        before do
          allow_any_instance_of(described_class).to receive(:badge_service).and_return(badge_service)

          allow(badge_service). to receive(:can_i_deploy_badge_url).and_return("http://badge_url")
          allow(badge_service). to receive(:error_badge_url).and_return("http://error_badge_url")

          allow_any_instance_of(CanIDeployApplicationVersionByTagToTagBadge).to receive(:application).and_return(application)
          allow_any_instance_of(CanIDeployApplicationVersionByTagToTagBadge).to receive(:version).and_return(version)
          allow_any_instance_of(CanIDeployApplicationVersionByTagToTagBadge).to receive(:results).and_return(results)
        end

        let(:branch_service) { class_double("PactBroker::Versions::BranchService").as_stubbed_const }
        let(:badge_service) { class_double("PactBroker::Badges::Service").as_stubbed_const }

        let(:application) { double("application") }
        let(:version) { double("version") }
        let(:environment) { double("environment") }
        let(:branch) { double("branch") }
        let(:results) { instance_double("PactBroker::Matrix::QueryResultsWithDeploymentStatusSummary", deployable?: true )}

        let(:path) { "/applications/Foo/latest-version/main/can-i-deploy/to/prod/badge"}

        subject { get(path, { label: "custom-label" }) }

        context "when everything is found" do
          it "return the badge URL" do
            expect(badge_service). to receive(:can_i_deploy_badge_url).with("main", "prod", "custom-label", true)
            expect(subject.headers["Location"]).to eq "http://badge_url"
          end
        end

        context "when the application is not found" do
          let(:application) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("application", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the version is not found" do
          let(:version) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("version", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end
      end
    end
  end
end
