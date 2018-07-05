class CreatePublications < ActiveRecord::Migration[5.2]
  def change
    create_table :publications do |t|
      t.boolean :active
      t.boolean :deleted
      t.string :title
      t.integer :year
      t.integer :lock_version
      t.text :xml
      t.text :pub_hash
    end
  end
end
