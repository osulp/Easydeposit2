class AddPubUrlToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :pub_url, :string
  end
end
