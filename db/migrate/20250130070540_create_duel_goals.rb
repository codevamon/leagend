class CreateDuelGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :duel_goals, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :duel, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.integer :minute

      t.timestamps
    end
  end
end
