class AddMethodParamsToJob < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :restartable_state, :string
    add_column :jobs, :restartable, :boolean, default: false
  end
end
