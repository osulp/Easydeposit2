class CreateJoinTableCasUserPublication < ActiveRecord::Migration[5.2]
  def change
    create_join_table :cas_users, :publications do |t|
      # t.index [:cas_user_id, :publication_id]
      # t.index [:publication_id, :cas_user_id]
    end
  end
end
