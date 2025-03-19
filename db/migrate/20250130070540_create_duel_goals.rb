class CreateDuelGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :duel_goals do |t|
      t.references :duel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true
      t.integer :minute

      t.timestamps
    end
  end
end
