class AddAbstractToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :abstract, :text
  end
end