class AddHashedUidToWebOfScienceSourceRecord < ActiveRecord::Migration[5.2]
  def change
    add_column :web_of_science_source_records, :hashed_uid, :string
  end
end
