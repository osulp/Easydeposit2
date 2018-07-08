class AddUserToJob < ActiveRecord::Migration[5.2]
  def change
    add_reference :jobs, :user, foreign_key: true
    add_reference :jobs, :cas_user, foreign_key: true
  end
end
