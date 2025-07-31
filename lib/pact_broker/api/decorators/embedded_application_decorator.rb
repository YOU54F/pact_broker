require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class EmbeddedApplicationDecorator < BaseDecorator
        camelize_property_names

        property :name

        link :self do | options |
          application_url(options[:base_url], represented)
        end
      end
    end
  end
end
