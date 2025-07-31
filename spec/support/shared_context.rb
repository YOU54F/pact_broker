require "pact_broker/test/test_data_builder"

RSpec.shared_context "stubbed services" do
  let(:pact_service) { class_double("PactBroker::Pacts::Service").as_stubbed_const }
  let(:application_service) { class_double("PactBroker::Applications::Service").as_stubbed_const }
  let(:version_service) { class_double("PactBroker::Versions::Service").as_stubbed_const }
  let(:webhook_service) { class_double("PactBroker::Webhooks::Service").as_stubbed_const }

  before do
    allow_any_instance_of(described_class).to receive(:pact_service).and_return(pact_service)
    allow_any_instance_of(described_class).to receive(:application_service).and_return(application_service)
    allow_any_instance_of(described_class).to receive(:version_service).and_return(version_service)
    allow_any_instance_of(described_class).to receive(:webhook_service).and_return(webhook_service)
  end
end

RSpec.shared_context "stubbed repositories" do

  let(:pact_repository) { instance_double("PactBroker::Pacts::Repository") }
  let(:application_repository) { instance_double("PactBroker::Applications::Repository") }
  let(:version_repository) { instance_double("PactBroker::Version::Repository") }

  before do
    allow(described_class).to receive(:pact_repository).and_return(pact_repository)
    allow(described_class).to receive(:application_repository).and_return(application_repository)
    allow(described_class).to receive(:version_repository).and_return(version_repository)
  end
end

RSpec.shared_context "test data builder" do
  let(:td) { PactBroker::Test::TestDataBuilder.new }
end