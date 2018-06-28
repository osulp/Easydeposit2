class AddAuthorToWebOfScienceSourceRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :web_of_science_source_records, :contactnames, :string
  end
end
