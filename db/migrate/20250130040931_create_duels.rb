class CreateDuels < ActiveRecord::Migration[8.0]
  def change
    create_table :duels, id: false, force: true do |t|
      # ID personalizado como varchar
      t.string :id, limit: 36, primary_key: true, null: false

      # Relaciones con equipos
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }

      # Relación con árbitro (opcional)
      t.references :referee, foreign_key: { to_table: :users }, null: true

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
      t.integer :status, default: 0 # Por ejemplo: 0 = pendiente, 1 = en progreso, 2 = finalizado
      t.integer :duel_type, default: 0 # Por ejemplo: 0 = amistoso, 1 = de apuesta

      # Detalles del duelo
      t.decimal :duration, precision: 8, scale: 2 # Duración en horas
      t.boolean :timing, default: false # false = por tiempo, true = por goles
      t.boolean :referee_required, default: false # Indica si el duelo requiere árbitro
      t.boolean :live, default: false # Indica si el duelo se transmite en vivo
      t.boolean :private, default: false # Indica si el duelo es privado
      t.boolean :streaming, default: false # Indica si hay transmisión en vivo
      t.boolean :audience, default: false # Indica si se permite público
      t.boolean :parking, default: false # Indica si hay estacionamiento disponible
      t.boolean :wifi, default: false # Indica si hay wifi disponible
      t.boolean :lockers, default: false # Indica si hay lockers disponibles
      t.boolean :snacks, default: false # Indica si hay snacks disponibles

      # Goles (totales, se pueden complementar con el modelo DuelGoal)
      t.integer :home_goals, default: 0
      t.integer :away_goals, default: 0

      # Otros campos
      t.boolean :hunted, default: false # Indica si el duelo es "cazado" (por ejemplo, para duelos rápidos)
      t.boolean :responsibility, default: false # Indica si los líderes asumen responsabilidad

      t.timestamps
    end

    # Índices adicionales (opcional, para mejorar consultas)
    add_index :duels, :start_date
    add_index :duels, :end_date
    add_index :duels, :status
    add_index :duels, :duel_type
    # add_index :duels, :referee_id
  end
end