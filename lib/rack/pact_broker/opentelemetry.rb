require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/instrumentation/rack/middlewares/stable/event_handler"

module Rack
  module PactBroker
    class OpenTelemetry
      def self.setup(app_builder = nil, configuration = PactBroker.configuration)
        ::OpenTelemetry::SDK.configure do |c|
          c.use "OpenTelemetry::Instrumentation::Rack"
          c.service_name = configuration.otel_service_name
        end

        if app_builder
          app_builder.use ::Rack::Events, [::OpenTelemetry::Instrumentation::Rack::Middlewares::Stable::EventHandler.new]
        end
      end

      at_exit do
        OpenTelemetry.tracer_provider.shutdown if defined?(OpenTelemetry) && OpenTelemetry.respond_to?(:tracer_provider)
      end
    end
  end
end