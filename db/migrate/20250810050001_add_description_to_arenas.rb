class AddDescriptionToArenas < ActiveRecord::Migration[8.0]
  def change
    add_column :arenas, :description, :text, null: true
  end
end
