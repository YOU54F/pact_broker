require "pact_broker/db/data_migrations/set_application_ids_for_verifications"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetApplicationIdsForVerifications.call(self)
  end
end
