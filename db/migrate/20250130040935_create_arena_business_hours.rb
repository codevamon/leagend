class CreateArenaBusinessHours < ActiveRecord::Migration[8.0]
  def change
    create_table :arena_business_hours, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :arena_id, limit: 36, null: false
      t.integer :weekday, null: false
      t.time :opens_at
      t.time :closes_at
      t.boolean :closed, default: false, null: false
      t.timestamps
    end

    add_foreign_key :arena_business_hours, :arenas, column: :arena_id, primary_key: :id
    add_index :arena_business_hours, [:arena_id, :weekday], unique: true
  end
end
