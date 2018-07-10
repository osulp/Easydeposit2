class CreateWebOfScienceSourceRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :web_of_science_source_records do |t|
      t.boolean :active
      t.string :database
      t.text :source_data
      t.string :source_fingerprint
      t.string :source_url
      t.string :authors
      t.string :uid
      t.string :doi
      t.string :pmid
    end
  end
end
