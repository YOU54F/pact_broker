require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_application("Foo")
    .delete_application("Bar")
    .create_application("Foo", main_branch: "main")
    .create_application("Bar", main_branch: "main")
    .publish_pact_the_old_way(consumer: "Foo", consumer_version: "1", provider: "Bar", content_id: "111", branch: "feat/x")
    .get_pacts_for_verification(provider_version_branch: "main")
    .verify_pact(provider_version_branch: "main", provider_version: "1", success: false)
    .verify_pact(provider_version_branch: "main", provider_version: "2", success: false)
    .can_i_merge(application: "Foo", version: "1")


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
