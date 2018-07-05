class AddPublicationToWebOfScienceSourceRecords < ActiveRecord::Migration[5.2]
  def change
    add_reference :web_of_science_source_records, :publication, foreign_key: true, index: true
  end
end
