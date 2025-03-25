class CreateOwners < ActiveRecord::Migration[8.0]
  def change
    create_table :owners, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.integer :level, default: 0, null: false

      t.timestamps
    end
  end
end
