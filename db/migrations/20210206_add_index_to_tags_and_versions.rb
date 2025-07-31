require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if postgres?
      run("CREATE INDEX tags_application_id_name_version_order_desc_index ON tags (application_id, name, version_order DESC);")
      run("CREATE INDEX versions_application_id_order_desc_index ON versions (application_id, \"order\" DESC);")
    else
      alter_table(:tags) do
        add_index([:application_id, :name, :version_order], name: "tags_application_id_name_version_order_index")
      end
    end
  end

  down do
    if postgres?
      run("DROP INDEX tags_application_id_name_version_order_desc_index")
      run("DROP INDEX versions_application_id_order_desc_index")
    else
      alter_table(:tags) do
        drop_index([:application_id, :name, :version_order], name: "tags_application_id_name_version_order_index")
      end
    end
  end
end
