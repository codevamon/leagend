class CreateClans < ActiveRecord::Migration[8.0]
  def change
    create_table :clans, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :slug, null: false, default: ""
      t.string :name
      t.string :country
      t.string :city
      t.string :neighborhood
      t.string :address
      t.text    :description
      t.integer :status
      t.integer :price
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.boolean :active, default: false

      t.timestamps
    end
    add_index :clans, :slug, unique: true
  end
end
