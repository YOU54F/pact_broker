require "pact_broker/api/resources/can_i_deploy_application_version_by_tag_to_tag"
require "pact_broker/matrix/service"

module PactBroker
  module Api
    module Resources
      describe CanIDeployApplicationVersionByTagToTag do
        include_context "stubbed services"

        before do
          allow(PactBroker::Matrix::Service).to receive(:can_i_deploy).and_return([])
          allow(application_service).to receive(:find_application_by_name).and_return(application)
          allow(PactBroker::Api::Decorators::MatrixDecorator).to receive(:new).and_return(decorator)
        end

        let(:application) { double("application") }
        let(:version) { double("version") }
        let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }
        let(:decorator) { double("decorator", to_json: "response_body") }
        let(:selectors) { double("selectors") }
        let(:options) { double("options") }

        subject { get(path, nil, "Content-Type" => "application/hal+json") }

        context "with tags" do
          before do
            allow(version_service).to receive(:find_by_application_name_and_latest_tag).and_return(version)
          end

          let(:path) { "/applications/Foo/latest-version/main/can-i-deploy/to/prod" }

          it "looks up the by tag" do
            expect(version_service).to receive(:find_by_application_name_and_latest_tag).with("Foo", "main")
            subject
          end

          it { is_expected.to be_a_hal_json_success_response }

          context "when the version does not exist" do
            let(:version) { nil }

            its(:status) { is_expected.to eq 404 }
          end
        end
      end
    end
  end
end
