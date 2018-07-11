class AddEmailAddressToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :reprintemails, :string
  end
end
