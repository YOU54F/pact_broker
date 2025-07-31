require "pact_broker/domain"
APPLICATION_LIMIT = 10
VERSION_LIMIT = 10

APPLICATIONS = PactBroker::Domain::Application.order(Sequel.desc(:id)).limit(APPLICATION_LIMIT).all

RSpec.describe "regression tests" do

  def can_i_deploy(application_name, version_number, to_tag)
    get("/can-i-deploy", { application: application_name, version: version_number, to: to_tag }, { "HTTP_ACCEPT" => "application/hal+json" })
  end

  APPLICATIONS.each do | application |
    describe application.name do

      versions = PactBroker::Domain::Version.where(application_id: application.id).order(Sequel.desc(:order)).limit(VERSION_LIMIT)
      versions.each do | version |
        describe "version #{version.number}" do
          it "has the same results for can-i-deploy" do

            can_i_deploy_response = can_i_deploy(application.name, version.number, "prod")
            results = {
              request: {
                name: "can-i-deploy",
                params: {
                  application_name: application.name,
                  version_number: version.number,
                  to_tag: "prod"
                }
              },
              response: {
                status: can_i_deploy_response.status,
                body: JSON.parse(can_i_deploy_response.body)
              }
            }

            Approvals.verify(results, :name => "regression_can_i_deploy_#{application.name}_version_#{version.number}", format: :json)
          end
        end
      end
    end
  end
end
