require "pact_broker/api/decorators/application_branches_decorator"

module PactBroker
  module Api
    module Decorators
      describe ApplicationBranchesDecorator do
        it "ensures the application is eager loaded for the branches collection" do
          expect(ApplicationBranchesDecorator.eager_load_associations).to include :application
        end

        describe "to_json" do
          let(:branch_1) { instance_double("PactBroker::Versions::Branch", name: "main", application: application_1, created_at: td.in_utc { DateTime.new(2020, 1, 1) }  ) }
          let(:application_1) { instance_double("PactBroker::Domain::Application", name: "Foo") }
          let(:branches) { [branch_1] }
          let(:options) do
            {
              user_options: {
                application: application_1,
                base_url: "http://example.org",
                request_url: "http://example.org/applications/Foo/branches"
              }
            }
          end
          let(:decorator) { ApplicationBranchesDecorator.new(branches) }

          subject { JSON.parse(decorator.to_json(options)) }

          it "generates json" do
            Approvals.verify(subject, :name => "application_branches_decorator", format: :json)
          end
        end
      end
    end
  end
end
