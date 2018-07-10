class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.belongs_to :publication, foreign_key: true
      t.string :name
      t.string :status
      t.text :message
    end
  end
end
