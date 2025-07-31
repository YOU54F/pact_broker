Sequel.migration do
  change do
    create_table(:labels, charset: "utf8") do
      String :name
      foreign_key :application_id, :applications
      primary_key [:application_id, :name], name: :labels_pk
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
