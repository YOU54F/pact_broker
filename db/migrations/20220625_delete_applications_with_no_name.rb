# There was a bug that caused a duplicate application to be created
# with a null name when updating the application in a certain way.
# It was fixed in be24a8ad650f0ed49993283b22ba1d1a744fb3e8.
# This migration deletes any applications with null names that are not referenced by any other rows,
# or assigns a name if the application is referenced so that it can be deleted through the API
# (I can't think of a reason why a application with a null name should be referenced, but better to be safe than sorry).
# The "find tables that reference applications" logic is done dynamically because Pactflow has extra tables not in the OSS.

# Query each table that references the applications table to determine
# if there are any rows in it that reference the application with the specified ID.
# @return [Boolean]
def application_is_unreferenced(application_id, table_foreign_keys)
  table_foreign_keys.any? do | (table_name, foreign_keys) |
    criteria = foreign_keys.flat_map do | fk |
      fk[:columns].collect do | column_name |
        { column_name => application_id }
      end
    end

    # SELECT 'one' FROM xxx where consumer_id = x or provider_id = x LIMIT 1
    !from(table_name).where(Sequel.|(*criteria)).empty?
  end
end

# Return a structure describing the tables and columns that reference the applications table.
# @return [Array] eg. [ [:integrations, [ { columns: [:consumer_id] }, { columns: [:provider_id] } ] ] ]
def get_table_foreign_keys
  table_foreign_keys = tables.sort.collect do | table_name |
    key_list = foreign_key_list(table_name).select{ |fk| fk[:table] == :applications }
    if key_list.any?
      [ table_name,  key_list]
    end
  end.compact

  # move the integrations table check first because that's the most likely candidate to have a referencing row
  table_foreign_keys.select{ |(table_name, _)| table_name == :integrations } | table_foreign_keys
end

# Deletes the application if it is unreferenced, or populates the name so it can
# be deleted through the API.
def delete_application_or_populate_name(row, table_foreign_keys)
  if application_is_unreferenced(row[:id], table_foreign_keys)
    from(:applications).where(id: row[:id]).delete
  else
    from(:applications).where(id: row[:id]).update(name: "Delete me #{row[:id]}")
  end
end

Sequel.migration do
  up do

    table_foreign_keys = get_table_foreign_keys

    from(:applications).where(name: nil).all.each do | row |
      delete_application_or_populate_name(row, table_foreign_keys)
    end
  end

  down do

  end
end
