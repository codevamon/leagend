class CreateArenaClosures < ActiveRecord::Migration[8.0]
  def change
    create_table :arena_closures, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :arena_id, limit: 36, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :reason
      t.timestamps
    end

    add_foreign_key :arena_closures, :arenas, column: :arena_id, primary_key: :id
    add_index :arena_closures, :arena_id
    add_index :arena_closures, :starts_at
    add_index :arena_closures, :ends_at
  end
end
