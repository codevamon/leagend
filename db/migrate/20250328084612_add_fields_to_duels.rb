class AddFieldsToDuels < ActiveRecord::Migration[8.0]
  def change
    add_column :duels, :why, :string   # "training", "hobbie"
    add_column :duels, :mode, :string        # "express", "scheduled"
  end
end
