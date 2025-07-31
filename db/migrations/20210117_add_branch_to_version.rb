Sequel.migration do
  change do
    alter_table(:versions) do
      add_column(:branch, String)
      add_column(:build_url, String)
      add_index([:application_id, :branch, :order], name: "versions_application_id_branch_order_index")
    end
  end
end
