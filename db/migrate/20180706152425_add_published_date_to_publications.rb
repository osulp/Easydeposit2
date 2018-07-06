class AddPublishedDateToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :pub_at, :datetime
  end
end
