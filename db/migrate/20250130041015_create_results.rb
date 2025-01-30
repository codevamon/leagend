class CreateResults < ActiveRecord::Migration[8.0]
  def change
    create_table :results do |t|
      t.references :duel, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.string :outcome

      t.timestamps
    end
  end
end
