require_relative "base_decorator"
require_relative "pact_application_decorator"
require_relative "timestamps"

module PactBroker
  module Api
    module Decorators
      class TagDecorator < BaseDecorator

        property :name

        include Timestamps

        link :self do | options |
          {
            title: "Tag",
            name: represented.name,
            href: tag_url(options[:base_url], represented)
          }
        end

        link :version do | options |
          {
            title: "Version",
            name: represented.version.number,
            href: version_url(options.fetch(:base_url), represented.version)
          }
        end

        link :application do | options |
          {
            title: "Application",
            name: represented.version.application.name,
            href: application_url(options.fetch(:base_url), represented.version.application)
          }
        end

      end
    end
  end
end