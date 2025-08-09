class CreateArenaVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :arena_verifications, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :arena_id, limit: 36, null: false
      t.string :submitted_by_id, limit: 36, null: false
      t.string :status, default: "draft", null: false
      t.text :rejection_reason
      t.string :payout_method
      t.json :payout_payload
      t.timestamps
    end

    add_foreign_key :arena_verifications, :arenas, column: :arena_id, primary_key: :id
    add_foreign_key :arena_verifications, :users, column: :submitted_by_id
    add_index :arena_verifications, :arena_id
    add_index :arena_verifications, :status
  end
end
