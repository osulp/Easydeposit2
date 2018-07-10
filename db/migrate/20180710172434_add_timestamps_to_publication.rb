class AddTimestampsToPublication < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :publications
  end
end
