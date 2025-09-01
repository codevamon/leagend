class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      # Polimórfica: Arena, Referee, etc.
      t.string :reservable_type, null: false
      t.string :reservable_id,   limit: 36, null: false

      # Usuario que paga y el que recibe (UUID para matchear users.id)
      t.string :payer_id,    limit: 36, null: false
      t.string :receiver_id, limit: 36, null: false

      # Ventana temporal
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false

      # Estado y dinero
      t.string  :status,        null: false, default: "held" # held | reserved | paid | canceled
      t.integer :amount_cents,  null: false, default: 0
      t.integer :duration_minutes,  null: false, default: 0
      t.string  :currency,      null: false, default: "COP"

      # Proveedor de pago / referencias
      t.string :payment_provider
      t.string :payment_ref

      # Otros
      t.text :notes

      t.timestamps
    end

    # Índices
    add_index :reservations, [:reservable_type, :reservable_id]
    add_index :reservations, [:reservable_type, :reservable_id, :starts_at, :ends_at], name: "idx_reservable_time_window"
    add_index :reservations, :starts_at
    add_index :reservations, :ends_at
    add_index :reservations, :status

    # Constraint de integridad temporal (Postgres lo respeta; en SQLite se ignora)
    add_check_constraint :reservations, "ends_at > starts_at", name: "chk_reservations_time_window"

    # FKs
    add_foreign_key :reservations, :users, column: :payer_id,    primary_key: :id
    add_foreign_key :reservations, :users, column: :receiver_id, primary_key: :id
  end
end
