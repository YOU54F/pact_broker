require "pact_broker/api/resources/can_i_deploy_application_version_by_tag_to_tag"
require "pact_broker/matrix/service"

module PactBroker
  module Api
    module Resources
      describe CanIDeployApplicationVersionByBranchToEnvironment do
        include_context "stubbed services"

        before do
          allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(environment)
          allow(PactBroker::Matrix::Service).to receive(:can_i_deploy).and_return([])
          allow(application_service).to receive(:find_application_by_name).and_return(application)
          allow(PactBroker::Api::Decorators::MatrixDecorator).to receive(:new).and_return(decorator)
          allow(version_service).to receive(:find_latest_by_application_name_and_branch_name).and_return(version)
        end

        let(:application) { double("application") }
        let(:version) { double("version") }
        let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }
        let(:decorator) { double("decorator", to_json: "response_body") }
        let(:selectors) { double("selectors") }
        let(:options) { double("options") }
        let(:environment) { double("environment") }
        let(:path) { "/applications/Foo/branches/main/latest-version/can-i-deploy/to-environment/dev" }

        subject { get(path, nil, "Content-Type" => "application/hal+json") }

        it "looks up the by branch" do
          expect(version_service).to receive(:find_latest_by_application_name_and_branch_name).with("Foo", "main")
          subject
        end

        it "checks if the version can be deployed to the environment" do
          expect(PactBroker::Matrix::Service).to receive(:can_i_deploy).with(anything, hash_including(environment_name: "dev"))
          subject
        end

        it { is_expected.to be_a_hal_json_success_response }

        context "when the environment does not exist" do
          let(:environment) { nil }

          its(:status) { is_expected.to eq 404 }
        end
      end
    end
  end
end
