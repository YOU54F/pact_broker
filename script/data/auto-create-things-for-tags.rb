#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_application("AutoDetectTestProvider")
    .create_environment(name: "prod", production: true)
    .create_application("AutoDetectTestProvider")
    .create_tagged_application_version(application: "AutoDetectTestProvider", version: "1", tag: "main")
    .deploy_to_prod(application: "AutoDetectTestProvider", version: "1")
    .publish_pact_the_old_way(consumer: "AutoDetectTestConsumer", provider: "AutoDetectTestProvider", consumer_version: "1", tag: "feat/x", content_id: "2111")
    .publish_pact_the_old_way(consumer: "AutoDetectTestConsumer", provider: "AutoDetectTestProvider", consumer_version: "2", tag: "feat/y", content_id: "21asdfd")
    .deploy_to_prod(application: "AutoDetectTestConsumer", version: "1")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
