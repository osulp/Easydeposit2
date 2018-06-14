class AddUidToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :wos_uid, :string
  end
end
