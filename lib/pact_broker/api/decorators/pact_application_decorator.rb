require "pact_broker/api/pact_broker_urls"
require_relative "embedded_version_decorator"
require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class PactApplicationDecorator < BaseDecorator

        property :name
        property :repository_url
        property :version, :class => "PactBroker::Domain::Version", :extend => PactBroker::Api::Decorators::EmbeddedVersionDecorator, :embedded => true

        link :self do | options |
          application_url(options[:base_url], represented)
        end
      end
    end
  end
end
