class CreateDuels < ActiveRecord::Migration[8.0]
  def change
    create_table :duels, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      # Relaciones con equipos (uuid string para flexibilidad entre Team o TeamMembership)
      t.string :home_team_id, limit: 36, null: false
      t.string :away_team_id, limit: 36, null: false

      # Relación con árbitro y mejor jugador
      t.references :referee, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.string :best_player_id, limit: 36, null: true

      # Fechas y ubicación
      t.datetime :start_date
      t.datetime :end_date
      t.string :address
      t.string :neighborhood
      t.string :city
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      # Presupuesto y precios
      t.decimal :price, precision: 8, scale: 2, default: 0.0
      t.decimal :budget, precision: 8, scale: 2, default: 0.0
      t.decimal :budget_place, precision: 8, scale: 2, default: 0.0
      t.decimal :budget_equipment, precision: 8, scale: 2, default: 0.0
      t.decimal :referee_price, precision: 8, scale: 2, default: 0.0

      # Estado y tipo de duelo
      t.integer :status, default: 0
      t.integer :duel_type, default: 0

      # Detalles del duelo
      t.decimal :duration, precision: 8, scale: 2
      t.boolean :timing, default: false
      t.boolean :referee_required, default: false
      t.boolean :live, default: false
      t.boolean :private, default: false
      t.boolean :streaming, default: false
      t.boolean :audience, default: false
      t.boolean :parking, default: false
      t.boolean :wifi, default: false
      t.boolean :lockers, default: false
      t.boolean :snacks, default: false

      t.integer :home_goals, default: 0
      t.integer :away_goals, default: 0

      t.boolean :hunted, default: false
      t.boolean :responsibility, default: false

      t.timestamps
    end

    # Índices
    add_index :duels, :start_date
    add_index :duels, :end_date
    add_index :duels, :status
    add_index :duels, :duel_type

    # Foreign key manual para best_player
    add_foreign_key :duels, :users, column: :best_player_id, primary_key: :id
  end
end
