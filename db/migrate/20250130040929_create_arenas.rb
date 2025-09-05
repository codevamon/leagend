class CreateArenas < ActiveRecord::Migration[8.0]
  def change
    create_table :arenas, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      t.string :owner_id, limit: 36, null: false

      t.string :name
      t.string :slug
      t.string :address
      t.string :city
      t.string :country
      t.string :neighborhood

      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.decimal :prestige, precision: 10, scale: 2, default: 0.0

      t.boolean :private, default: false
      t.boolean :rentable, default: false
      t.decimal :price_per_hour, precision: 8, scale: 2, default: 0.0

      # Campos de AddArenaFields integrados
      t.string  :description, null: true
      t.string  :status, default: "unverified", null: false
      t.json    :amenities, default: {}
      t.text    :cancellation_policy
      t.integer :deposit_cents, default: 0
      t.string  :currency, default: "COP", null: false

      t.timestamps
    end

    add_foreign_key :arenas, :owners, column: :owner_id, primary_key: :id
    add_index :arenas, :slug, unique: true
    add_index :arenas, :status
  end
end
