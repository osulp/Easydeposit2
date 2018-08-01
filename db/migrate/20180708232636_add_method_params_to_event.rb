class AddMethodParamsToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :restartable_state, :string
    add_column :events, :restartable, :boolean, default: false
  end
end
