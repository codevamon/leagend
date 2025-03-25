class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      # Polimórfica: Arena o Referee
      t.string :reservable_type, null: false
      t.string :reservable_id, limit: 36, null: false

      # Usuario que paga y el que recibe
      t.string :payer_id, limit: 36, null: false
      t.string :receiver_id, limit: 36, null: false

      # Fechas y costos
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :price_per_hour, precision: 8, scale: 2
      t.decimal :total_price, precision: 10, scale: 2
      t.boolean :confirmed, default: false
      t.string :purpose

      t.timestamps
    end

    add_index :reservations, [:reservable_type, :reservable_id]
    add_foreign_key :reservations, :users, column: :payer_id, primary_key: :id
    add_foreign_key :reservations, :users, column: :receiver_id, primary_key: :id
  end
end
