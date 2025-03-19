class CreateCallups < ActiveRecord::Migration[8.0]
  def change
    create_table :callups do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :duel, null: false, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :callups, [:team_id, :user_id, :duel_id], unique: true
  end
end