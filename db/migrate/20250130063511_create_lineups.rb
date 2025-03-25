class CreateLineups < ActiveRecord::Migration[8.0]
  def change
    create_table :lineups, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
    
      t.references :duel, null: false, foreign_key: true, type: :uuid
      t.references :teamable, polymorphic: true, null: false, type: :string
      t.references :user, null: false, foreign_key: true, type: :uuid
    
      t.string :position
      t.integer :formation
      t.timestamps
    end
    
  end
end
