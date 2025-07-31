require "pact_broker/api/resources/can_i_deploy_application_version_by_branch_to_environment_badge"

module PactBroker
  module Api
    module Resources
      describe CanIDeployApplicationVersionByBranchToEnvironmentBadge do
        before do
          allow_any_instance_of(described_class).to receive(:branch_service).and_return(branch_service)
          allow_any_instance_of(described_class).to receive(:badge_service).and_return(badge_service)

          allow(branch_service).to receive(:find_branch).and_return(branch)
          allow(badge_service). to receive(:can_i_deploy_badge_url).and_return("http://badge_url")
          allow(badge_service). to receive(:error_badge_url).and_return("http://error_badge_url")

          allow_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:application).and_return(application)
          allow_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:version).and_return(version)
          allow_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:environment).and_return(environment)
          allow_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:results).and_return(results)
        end

        let(:branch_service) { class_double("PactBroker::Versions::BranchService").as_stubbed_const }
        let(:badge_service) { class_double("PactBroker::Badges::Service").as_stubbed_const }

        let(:application) { double("application") }
        let(:version) { double("version") }
        let(:environment) { double("environment") }
        let(:branch) { double("branch") }
        let(:results) { instance_double("PactBroker::Matrix::QueryResultsWithDeploymentStatusSummary", deployable?: true )}

        let(:path) { "/applications/Foo/branches/main/latest-version/can-i-deploy/to-environment/dev/badge" }

        subject { get(path, { label: "custom-label" }) }

        context "when everything is found" do
          it "return the badge URL" do
            expect(badge_service). to receive(:can_i_deploy_badge_url).with("main", "dev", "custom-label", true)
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

          it "attempts to find the branch" do
            expect(branch_service).to receive(:find_branch).with(application_name: "Foo", branch_name: "main")
            subject
          end
        end

        context "when the version is not found and the branch is not found" do
          let(:version) { nil }
          let(:branch) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("branch", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the version is not found and the branch is found" do
          let(:version) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("version", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the environment is not found" do
          let(:environment) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("environment", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when there is an error creating the badge URL" do
          before do
            allow(badge_service). to receive(:can_i_deploy_badge_url).and_raise(StandardError.new("some error"))
            allow_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:log_and_report_error).and_return("error_ref")
          end

          it "logs and reports the error" do
            expect_any_instance_of(CanIDeployApplicationVersionByBranchToEnvironmentBadge).to receive(:log_and_report_error)
            subject
          end

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("error", "reference: error_ref")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end
      end
    end
  end
end
