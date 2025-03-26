class CreateResults < ActiveRecord::Migration[8.0]
  def change
    create_table :results, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      t.references :duel, null: false, foreign_key: true, type: :uuid

      # Relaciones polimórficas
      t.references :home_teamable, polymorphic: true, null: false, type: :string
      t.references :away_teamable, polymorphic: true, null: false, type: :string

      t.references :referee, type: :uuid, foreign_key: { to_table: :users }, null: true

      # Jugador destacado (opcional)
      t.string :best_player_id, limit: 36, null: true

      t.integer :outcome, default: 0

      t.timestamps
    end

    # Índices
    add_index :results, [:duel_id, :home_teamable_id, :home_teamable_type], name: 'index_results_on_duel_and_home_teamable'
    add_index :results, [:duel_id, :away_teamable_id, :away_teamable_type], name: 'index_results_on_duel_and_away_teamable'

    # Foreign key para jugador destacado
    add_foreign_key :results, :users, column: :best_player_id, primary_key: :id
  end
end
