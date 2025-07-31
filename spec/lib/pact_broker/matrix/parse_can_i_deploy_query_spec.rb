require "pact_broker/matrix/parse_can_i_deploy_query"

module PactBroker
  module Matrix
    describe ParseCanIDeployQuery do
      describe ".call" do
        let(:params) do
          {
            application: "foo",
            version: "1",
            environment: "prod"
          }
        end

        subject(:result) { ParseCanIDeployQuery.call(params) }

        let(:parsed_selectors) { result.first }
        let(:parsed_options) { result.last }

        describe "parsed_options" do
          subject { parsed_options }

          its([:latestby]) { is_expected.to eq "cvp" }
          its([:latest]) { is_expected.to eq nil }
          its([:environment_name]) { is_expected.to eq "prod" }
          its([:ignore_selectors]) { is_expected.to eq [] }

          context "with applications to ignore" do
            before do
              params[:ignore] = ["foo", "bar", {"a" => "b"}]
            end

            its([:ignore_selectors]) do
              is_expected.to eq [
                PactBroker::Matrix::UnresolvedSelector.new(application_name: "foo"),
                PactBroker::Matrix::UnresolvedSelector.new(application_name: "bar")
              ]
            end
          end

          context "with application selectors to ignore" do
            before do
              params[:ignore] = [{ application: "foo" }, { application: "bar", version: "2" }]
            end

            its([:ignore_selectors]) do
              is_expected.to eq [
                PactBroker::Matrix::UnresolvedSelector.new(application_name: "foo"),
                PactBroker::Matrix::UnresolvedSelector.new(application_name: "bar", application_version_number: "2")
              ]
            end
          end

          context "with a tag" do
            let(:params) do
              {
                application: "foo",
                version: "1",
                to: "prod"
              }
            end

            its([:latestby]) { is_expected.to eq "cvp" }
            its([:latest]) { is_expected.to eq true }
            its([:tag]) { is_expected.to eq "prod" }
          end
        end

        describe "parsed_selectors" do
          subject { parsed_selectors }

          it { is_expected.to eq [PactBroker::Matrix::UnresolvedSelector.new(application_name: "foo", application_version_number: "1")] }
        end
      end
    end
  end
end
