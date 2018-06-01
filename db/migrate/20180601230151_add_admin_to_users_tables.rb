class AddAdminToUsersTables < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :admin, :boolean, default: false
    add_column :cas_users, :admin, :boolean, default: false
  end
end
