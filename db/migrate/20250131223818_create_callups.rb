class CreateCallups < ActiveRecord::Migration[8.0]
  def change
    create_table :callups, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      t.references :duel, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :teamable, polymorphic: true, null: false, type: :string

      t.integer :status, default: 0

      t.timestamps
    end

    add_index :callups, [:duel_id, :user_id, :teamable_id, :teamable_type], unique: true
  end
end
