require "roar/json/hal"
require "pact_broker/api/pact_broker_urls"
require_relative "embedded_version_decorator"
require_relative "pagination_links"
require "pact_broker/domain/application"
require "pact_broker/api/decorators/application_decorator"

module PactBroker
  module Api
    module Decorators
      class ApplicationsDecorator < BaseDecorator

        collection :entries, :as => :applications, :class => PactBroker::Domain::Application, :extend => PactBroker::Api::Decorators::ApplicationDecorator, embedded: true

        include PaginationLinks

        def self.eager_load_associations
          PactBroker::Api::Decorators::ApplicationDecorator.eager_load_associations
        end

        link :self do | options |
          applications_url options[:base_url]
        end

        link :'pb:applications-with-label' do | options |
          {
            title: "Find applications by label",
            href: "#{applications_url(options[:base_url])}/label/{label}",
            templated: true
          }
        end

        links :'pb:applications' do | options |
          represented.collect{ | application | { href: application_url(options[:base_url], application), title: "Application", name: application.name } }
        end

        # TODO deprecate in v3
        links :applications do | options |
          represented.collect{ | application | { href: application_url(options[:base_url], application), :title => application.name, name: "DEPRECATED - please use pb:applications" } }
        end
      end

      class DeprecatedApplicationDecorator < PactBroker::Api::Decorators::ApplicationDecorator
        property :title, getter: ->(_) { "DEPRECATED - Please use the embedded applications collection" }
      end

      class NonEmbeddedApplicationCollectionDecorator < BaseDecorator
        collection :entries, :as => :applications, :class => PactBroker::Domain::Application, :extend => DeprecatedApplicationDecorator, embedded: false
      end

      # TODO deprecate this - breaking change for v 3.0
      class DeprecatedApplicationsDecorator < ApplicationsDecorator
        def to_hash(options)
          embedded_application_hash = super
          non_embedded_application_hash = NonEmbeddedApplicationCollectionDecorator.new(represented).to_hash(options)
          embedded_application_hash.merge(non_embedded_application_hash)
        end
      end
    end
  end
end
