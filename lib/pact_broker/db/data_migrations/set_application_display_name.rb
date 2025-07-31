require "pact_broker/db/data_migrations/helpers"
require "pact_broker/applications/generate_display_name"

module PactBroker
  module DB
    module DataMigrations
      class SetApplicationDisplayName
        extend Helpers
        extend PactBroker::Applications::GenerateDisplayName

        def self.call(connection)
          if columns_exist?(connection, :applications, [:name, :display_name])
            connection[:applications].where(display_name: nil).each do | row |
              connection[:applications]
                .where(id: row[:id])
                .update(display_name: generate_display_name(row[:name]))
            end
          end
        end
      end
    end
  end
end
