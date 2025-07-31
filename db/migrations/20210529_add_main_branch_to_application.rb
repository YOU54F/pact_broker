Sequel.migration do
  up do
    alter_table(:applications) do
      add_column(:main_branch, String)
    end

    # TODO
    # alter_table(:applications) do
    #   drop_column(:main_development_branches)
    # end
  end

  down do
    alter_table(:applications) do
      drop_column(:main_branch)
    end
  end
end
