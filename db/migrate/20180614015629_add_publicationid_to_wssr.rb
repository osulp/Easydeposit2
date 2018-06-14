class AddPublicationidToWssr < ActiveRecord::Migration[5.2]
  # publication_id is required for web_of_science_source_records because of the has_one publication association
  def change
    add_column :web_of_science_source_records, :publication_id, :integer
  end
end
