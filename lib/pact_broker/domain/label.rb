require "pact_broker/dataset"

module PactBroker
  module Domain
    class Label < Sequel::Model
      set_primary_key([:name, :application_id])
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      associate(:many_to_one, :application, :class => "PactBroker::Domain::Application", :key => :application_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

      dataset_module do
        include PactBroker::Dataset
      end
    end
  end
end

# Table: labels
# Primary Key: (name, application_id)
# Columns:
#  name           | text                        |
#  application_id | integer                     |
#  created_at     | timestamp without time zone | NOT NULL
#  updated_at     | timestamp without time zone | NOT NULL
# Indexes:
#  labels_pk | PRIMARY KEY btree (application_id, name)
# Foreign key constraints:
#  labels_application_id_fkey | (application_id) REFERENCES applications(id)
