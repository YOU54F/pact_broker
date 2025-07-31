require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/publish_contract_decorator"
require "pact_broker/api/decorators/embedded_version_decorator"

module PactBroker
  module Api
    module Decorators
      class PublishContractsResultsDecorator < BaseDecorator
        camelize_property_names

        property :logs, getter: ->(represented:, **) { represented.notices.collect{ | notice | { level: notice.type, message: notice.text, deprecationWarning: "Replaced by notices" } } }
        property :notices, getter: ->(represented:, **) { represented.notices.collect(&:to_h) }

        property :application, embedded: true, extend: EmbeddedApplicationDecorator
        property :version, embedded: true, extend: EmbeddedVersionDecorator

        link :'pb:application' do | options |
          {
            title: "Application",
            name: represented.application.name,
            href: application_url(options.fetch(:base_url), represented.application)
          }
        end

        link :'pb:application-version' do | options |
          {
            title: "Application version",
            name: represented.version.number,
            href: version_url(options.fetch(:base_url), represented.version)
          }
        end

        links :'pb:application-version-tags' do | options |
          represented.tags.collect do | tag |
            {
              title: "Tag",
              name: tag.name,
              href: tag_url(options.fetch(:base_url), tag)
            }
          end
        end

        links :'pb:contracts' do | options |
          represented.contracts.collect do | contract |
            {
              title: "Pact",
              name: contract.name,
              href: pact_url(options.fetch(:base_url), contract)
            }
          end
        end
      end
    end
  end
end
