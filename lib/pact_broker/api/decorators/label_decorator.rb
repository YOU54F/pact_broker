require_relative "base_decorator"
require_relative "pact_application_decorator"
require_relative "timestamps"

module PactBroker
  module Api
    module Decorators
      class LabelDecorator < BaseDecorator

        property :name

        include Timestamps

        # This method is overridden to conditionally render the links based on the user_options
        def to_hash(options)
          hash = super

          unless options.dig(:user_options, :hide_label_decorator_links)
            hash[:_links] = {
              self: {
                title: "Label",
                name: represented.name,
                href: label_url(represented, options.dig(:user_options, :base_url))
              },
              application: {
                title: "Application",
                name: represented.application.name,
                href: application_url(options.dig(:user_options, :base_url), represented.application)
              }
            }
          end

          hash
        end
      end
    end
  end
end
