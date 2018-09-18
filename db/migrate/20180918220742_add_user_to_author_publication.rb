class AddUserToAuthorPublication < ActiveRecord::Migration[5.2]
  def change
    add_reference :author_publications, :user, foreign_key: true
  end
end
