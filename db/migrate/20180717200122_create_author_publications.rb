class CreateAuthorPublications < ActiveRecord::Migration[5.2]
  def change
    create_table :author_publications do |t|
      t.belongs_to :publication
      t.string :email
      t.string :name
      t.string :primary_affiliation

      t.timestamps
    end
  end
end
