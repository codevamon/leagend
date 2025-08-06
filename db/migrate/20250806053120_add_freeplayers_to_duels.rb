class AddFreeplayersToDuels < ActiveRecord::Migration[8.0]
  def change
    add_column :duels, :allow_freeplayers, :boolean, default: false
  end
end
