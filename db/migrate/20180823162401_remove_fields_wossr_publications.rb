class RemoveFieldsWossrPublications < ActiveRecord::Migration[5.2]
  def change
    remove_column :web_of_science_source_records, :doi
    remove_column :web_of_science_source_records, :pmid
    remove_column :web_of_science_source_records, :authors
    remove_column :publications, :title
    remove_column :publications, :year
  end
end
