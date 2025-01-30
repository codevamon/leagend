class CreateLineups < ActiveRecord::Migration[8.0]
  def change
    create_table :lineups do |t|
      t.references :duel, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :position

      t.timestamps
    end
  end
end
