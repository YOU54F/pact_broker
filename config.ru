require "pact_broker"

ENV["TZ"] = "Australia/Melbourne"

# Setup OpenTelemetry
# ENV['OTEL_TRACES_EXPORTER'] = 'console,otlp' # 'console,otlp' to export to both console and OTLP exporter
# ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = "http://localhost:4318" # Uncomment and set to your OTLP endpoint if not using the default

app = PactBroker::App.new do | config |
  config.log_stream = :stdout
  config.base_urls = ["http://localhost:9292"]
  config.database_url = "sqlite:////tmp/pact_broker_database.sqlite3"
  # Uncomment the following lines to enable OpenTelemetry
  # config.otel_enabled = true # false by default
  # config.otel_service_name = "pact_broker_example_app"
end

run app
