require "pact_broker/api/resources/matrix"

module PactBroker
  module Api
    module Resources
      class CanIDeployApplicationVersionByTagToTag < Matrix
        def resource_exists?
          !!version
        end

        def policy_name
          :'versions::version'
        end

        def malformed_request?
          false
        end

        private

        def selectors
          @selectors ||= [
                            PactBroker::Matrix::UnresolvedSelector.new(
                              application_name: application_name,
                              latest: true,
                              tag: identifier_from_path[:tag],
                            )
                          ]

        end

        def options
          @options ||= {
                          latestby: "cvp",
                          latest: true,
                          tag: identifier_from_path[:to]
                        }
        end

        def version
          @version ||= version_service.find_by_application_name_and_latest_tag(identifier_from_path[:application_name], identifier_from_path[:tag])
        end
      end
    end
  end
end
