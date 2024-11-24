# frozen_string_literal: true

require "pact_broker"
require "pact_broker/app"
require "rspec/mocks"
include RSpec::Mocks::ExampleMethods
require_relative "../../service_consumers/hal_relation_proxy_app"

PactBroker.configuration.base_urls = ["http://example.org"]

pact_broker = PactBroker::App.new { |c| c.database_connection = PactBroker::TestDatabase.connection_for_test_database }
app_to_verify = HalRelationProxyApp.new(pact_broker)

require "sbmt/pact"
require "sbmt/pact/rspec"
RSpec.describe "Verify consumers for Pact Broker", :pact do

  http_pact_provider "Pact Broker", opts: { 

    # rails apps should be automatically detected
    # if you need to configure your own app, you can do so here

    app: app_to_verify,
    # start rackup with a different port. Useful if you already have something
    # running on the default port *9292*
    http_port: 9393, 
    
    # Set the log level, default is :info
  
    log_level: :info,
    
    # fail_if_no_pacts_found: true,

    # Pact Sources

    # Local pacts from a directory
    # Default is File.expand_path('../../../spec/internal/pacts', __dir__)
    
    # pact_dir: File.expand_path('../../../../consumer/spec/internal/pacts', __dir__),
    
    
    # Broker pacts

    # Broker credentials
  
    # broker_username: "pact_workshop", # can be set via PACT_BROKER_USERNAME env var
    # broker_password: "pact_workshop", # can be set via PACT_BROKER_PASSWORD env var
    # broker_token: "pact_workshop", # can be set via PACT_BROKER_TOKEN env var
  
    # Remote pact via a uri, traditionally triggered via webhooks
    # when a pact that requires verification is published
  
    # can be set via PACT_URL env var
    pact_uri: File.expand_path("../../../pacts/pact.json", __dir__),
    # pact_uri: "https://raw.githubusercontent.com/pact-foundation/pact_broker-client/master/spec/pacts/pact_broker_client-pact_broker.json",
    # pact_uri: "http://localhost:9292/pacts/provider/Pact%20Broker/consumer/Pact%20Broker%20Client/version/96532124f3a53a499276c69ff2df785b8377588e",
    
    # to dynamically fetch pacts from a broker
    # broker_url: "http://localhost:9292", # can be set via PACT_BROKER_URL env var

    # these are the default consumer_selectors from the broker verification endpoint
    # if you don't set them via consumer_selectors in ruby
    # consumer_selectors: [{"deployedOrReleased" => true, "mainBranch" => true, "matchingBranch" => true}],
 
    # addition dynamic selection verification options
 
    # enable_pending: true,
    # include_wip_pacts_since: "2021-01-01",
  

    # Publish verification results to the broker

    # publish_verification_results: ENV['PACT_PUBLISH_VERIFICATION_RESULTS'] == 'true',
    # provider_version: `git rev-parse HEAD`.strip,
    # provider_version_branch: `git rev-parse --abbrev-ref HEAD`.strip,
    # provider_version_tags: [`git rev-parse --abbrev-ref HEAD`.strip],
    # provider_build_uri: "YOUR CI URL HERE",
    
  }

  before_state_setup do
    PactBroker::TestDatabase.truncate
  end

  after_state_teardown do
    PactBroker::TestDatabase.truncate
  end

  # TODO: scope provider states for consumer names?
  # Pact.provider_states_for "Pact Broker Client" do
  provider_state "an environment with name test exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test")
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for deployment" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
    end
  end

  # provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo does not exist" do
  #   no_op
  # end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with 2 environments that aren't test available for deployment" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_environment("prod")
        .create_environment("dev")
    end
  end

  # provider_state "the pb:latest-tagged-version relation exists in the index resource" do
  #   no_op
  # end

  provider_state "'Condor' exists in the pact-broker with the latest tagged 'production' version 1.2.3" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("production")
        .create_consumer_version("2.0.0")
    end
  end

  # provider_state "the pb:latest-version relation exists in the index resource" do
  #   no_op
  # end

  provider_state "'Condor' exists in the pact-broker with the latest version 1.2.3" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_consumer_version("1.0.0")
        .create_consumer_version("1.2.3")
    end
  end

  provider_state "the 'Pricing Service' and 'Condor' already exist in the pact-broker" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_provider("Pricing Service")
    end
  end

  provider_state "the pact for Foo Thing version 1.2.3 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo Thing", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "7.8.9", number: 2)
        .create_consumer_version("2.0.0")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "7.8.9", number: 2)
        .create_consumer_version("2.0.0")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 and 1.2.4 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6, and 1.2.4 unsuccessfully by 9.9.9" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "9.9.9", success: false)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6 with tag prod, and 1.2.4 unsuccessfully by 9.9.9" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .use_provider("Bar")
        .use_provider_version("4.5.6")
        .create_provider_version_tag("prod")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "9.9.9", success: false)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been verified by Bar version 4.5.6 and version 5.6.7" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "5.6.7", number: 2)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6 (tagged prod) and version 5.6.7" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .create_verification(provider_version: "4.5.6")
        .use_provider_version("4.5.6")
        .create_provider_version_tag("prod")
        .create_verification(provider_version: "5.6.7", number: 2)
    end
  end

  # provider_state "the 'Pricing Service' does not exist in the pact-broker" do
  #   no_op
  # end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      TestDataBuilder.new.create_pricing_service.create_provider_version("1.3.0")
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      require "pact_broker/pacts/service"
      allow(PactBroker::Pacts::Service).to receive(:create_or_update_pact).and_raise("an error")
    end
    tear_down do
      allow(PactBroker::Pacts::Service).to receive(:create_or_update_pact).and_call_original
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0")
        .create_pricing_service
        .create_pact
    end
  end

  # provider_state "no pact between Condor and the Pricing Service exists" do
  #   no_op
  # end

  provider_state "the 'Pricing Service' and 'Condor' already exist in the pact-broker, and Condor already has a pact published for version 1.3.0" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0")
        .create_pricing_service
        .create_pact
    end
  end

  provider_state "'Condor' already exist in the pact-broker, but the 'Pricing Service' does not" do
    set_up do
      TestDataBuilder.new.create_condor
    end
  end

  provider_state "'Condor' exists in the pact-broker" do
    set_up do
      TestDataBuilder.new.create_condor.create_consumer_version("1.3.0")
    end
  end

  provider_state "'Condor' exists in the pact-broker with version 1.3.0, tagged with 'prod'" do
    set_up do
      TestDataBuilder.new
        .create_pacticipant("Condor")
        .create_version("1.3.0")
        .create_tag("prod")
    end
  end

  # provider_state "'Condor' does not exist in the pact-broker" do
  #   no_op
  # end

   provider_state "a pact between Condor and the Pricing Service exists for the production version of Condor" do
     set_up do
       TestDataBuilder.new
         .create_consumer("Condor")
        .create_consumer_version("1.3.0")
        .create_consumer_version_tag("prod")
         .create_provider("Pricing Service")
         .create_pact
     end
   end

   provider_state "a pacticipant version with production details exists for the Pricing Service" do
     set_up do
       # Your set up code goes here
     end
   end

  #  provider_state "no pacticipant version exists for the Pricing Service" do
  #    no_op
  #  end

  provider_state "a latest pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_consumer_version("1.3.0")
          .create_provider("Pricing Service")
          .create_pact
    end
  end

  provider_state "tagged as prod pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_consumer_version("1.3.0")
          .create_consumer_version_tag("prod")
          .create_provider("Pricing Service")
          .create_pact
    end
  end

  provider_state "a webhook with the uuid 696c5f93-1b7f-44bc-8d03-59440fcaa9a0 exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_provider("Pricing Service")
          .create_webhook(uuid: "696c5f93-1b7f-44bc-8d03-59440fcaa9a0")
    end
  end

  # provider_state "the pacticipant relations are present" do
  #   no_op
  # end

  provider_state "a pacticipant with name Foo exists" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
    end
  end

  # provider_state "the pb:pacticipant-version relation exists in the index resource" do
  #   no_op
  # end

  # provider_state "version 26f353580936ad3b9baddb17b00e84f33c69e7cb of pacticipant Foo does not exist" do
  #   no_op
  # end

  provider_state "version 26f353580936ad3b9baddb17b00e84f33c69e7cb of pacticipant Foo does exist" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("26f353580936ad3b9baddb17b00e84f33c69e7cb")
    end
  end

  # provider_state "the pb:publish-contracts relations exists in the index resource" do
  #   no_op
  # end

  # provider_state "the pb:environments relation exists in the index resource" do
  #   no_op
  # end

  provider_state "provider Bar version 4.5.6 has a successful verification for Foo version 1.2.3 tagged prod and a failed verification for version 3.4.5 tagged prod" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_provider("Bar")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("prod")
        .create_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("3.4.5")
        .create_consumer_version_tag("prod")
        .create_pact(json_content: TestDataBuilder.new.random_json_content("Foo", "Bar"))
        .create_verification(provider_version: "4.5.6", success: false)
    end
  end

  provider_state "an environment exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", contacts: [ { name: "foo", details: { emailAddress: "foo@bar.com" } }])
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for release" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
    end
  end

  provider_state "an environment with name test and UUID 16926ef3-590f-4e3f-838e-719717aa88c9 exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
    end
  end

  provider_state "an version is deployed to environment with UUID 16926ef3-590f-4e3f-838e-719717aa88c9 with target customer-1" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_deployed_version_for_consumer_version(uuid: "ff3adecf-cfc5-4653-a4e3-f1861092f8e0", target: "customer-1")
    end
  end

  provider_state "a currently deployed version exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_deployed_version_for_consumer_version(uuid: "ff3adecf-cfc5-4653-a4e3-f1861092f8e0")
    end
  end

  # provider_state "the pb:pacticipant-branch relation exists in the index resource" do
  #   no_op
  # end

  provider_state "a branch named main exists for pacticipant Foo" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("1", branch: "main")
    end
  end
  
end
