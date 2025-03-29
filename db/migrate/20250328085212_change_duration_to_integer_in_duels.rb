class ChangeDurationToIntegerInDuels < ActiveRecord::Migration[8.0]
  def change
    remove_column :duels, :duration
    add_column :duels, :duration, :integer
  end
end
