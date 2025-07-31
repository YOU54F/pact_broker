require_relative "base_decorator"

module PactBroker

  module Api

    module Decorators

      class BasicApplicationDecorator < BaseDecorator

        property :name

        link :self do | options |
          application_url(options[:base_url], represented)
        end

      end
    end
  end
end
