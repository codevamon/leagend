class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name
      t.references :club, null: false, foreign_key: true
      t.references :clan, null: false, foreign_key: true
      t.integer :status
      t.timestamps
    end
  end
end
