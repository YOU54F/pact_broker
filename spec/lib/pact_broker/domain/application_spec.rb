require "pact_broker/domain/application"

module PactBroker
  module Domain
    describe Application do
      describe "#latest_version" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_consumer_version("2")
            .create_consumer_version("3")
            .create_consumer("Bar")
            .create_consumer_version("10")
            .create_consumer_version("11")
            .create_consumer_version("12")
        end

        it "lazy loads" do
          applications = Application.order(:id).all
          expect(applications.first.latest_version.number).to eq "3"
          expect(applications.last.latest_version.number).to eq "12"
        end

        it "eager_loads" do
          applications = Application.order(:id).eager(:latest_version).all
          expect(applications.first.associations[:latest_version].number).to eq "3"
          expect(applications.last.associations[:latest_version].number).to eq "12"
        end
      end
    end
  end
end
