class BuildDatabase < ActiveRecord::Migration[5.2]
  def change
    create_table :authors do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :preferred_first_name
      t.string :preferred_last_name
      t.string :preferred_middle_name

      t.timestamps
    end

    create_table :contributions do |t|
      t.integer :author_id
      t.integer :publication_id
      t.string :status

      t.timestamps
    end

    add_index :contributions, :publication_id
    add_index :contributions, :author_id
    add_index :contributions, [:publication_id, :author_id]

    create_table :publications do |t|
      t.boolean :active
      t.boolean :deleted
      t.string :title
      t.integer :year
      t.integer :lock_version
      t.text :xml
      t.text :pub_hash
      t.timestamps
    end

    create_table :web_of_science_source_records do |t|
      t.boolean :active
      t.string :database
      t.text :source_data
      t.string :source_fingerprint
      t.string :uid

      t.timestamps null: false
    end
    add_index :web_of_science_source_records, :uid, name: 'web_of_science_uid_index'

    create_table :publication_identifiers do |t|
      t.integer :publication_id
      t.string :identifier_type
      t.string :identifier_value
      t.string :identifier_uri
      t.string :certainty

      t.timestamps
    end

    add_index :publication_identifiers, [:publication_id, :identifier_type], name: 'pub_identifier_index_by_type_and_pub'
    add_index :publication_identifiers, [:identifier_type, :publication_id], name: 'pub_identifier_index_by_pub_and_type'
    add_index :publication_identifiers, :publication_id
    add_index :publication_identifiers, :identifier_type
  end
end
