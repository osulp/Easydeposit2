class AddAasmStateToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :aasm_state, :string
  end
end
